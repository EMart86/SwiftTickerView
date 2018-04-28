//
//  SwiftTickerView.swift
//  Pods
//
//  Created by Martin Eberl on 15.08.17.
//
//

import GLKit


public protocol SwiftTickerProviderProtocol {
    var hasContent: Bool { get }
    var next: Any { get }
}

public protocol SwiftTickerDelegate: class {
    func tickerView(willResume ticker: SwiftTickerView)
    func tickerView(willStart ticker: SwiftTickerView)
    func tickerView(willStop ticker: SwiftTickerView)
    func tickerView(didPress view: UIView, content: Any?)
}

public protocol SwiftTickerViewProvider {
    func tickerView(_ tickerView: SwiftTickerView, prepareSeparator separator: UIView)
    func tickerView(_ tickerView: SwiftTickerView, viewFor: Any) -> (UIView, reuseIdentifier: String?)
}

public final class SwiftTickerView: GLKView {
    private let separatorIdentifier = "SeparatorIdentifier"
    private let dontReuseIdentifier = "DontReuseIdentifier"
    private let interval = 120
    public enum Direction {
        case horizontalLeftToRight
        case horizontalRightToLeft
        case verticalTopToBottom
        case verticalBottomToTop
    }
    
    public var direction: Direction = .horizontalLeftToRight {
        didSet {
            stop()
            resume()
        }
    }
    
    public var pixelPerSecond: CGFloat = 60
    public var separator: String?
    private var separatorView: UIView.Type?
    private var separatorNib: UINib?
    
    public var distanceBetweenNodes: CGFloat = 8
    public private(set) var isRunning = false
    
    private var lastNodeWasSeparator: Bool = false
    private var displayLink: CADisplayLink?
    private var nodeViews = [(key: String, view: UIView, content: Any?)]()
    private var reusableSeparatorViews = [(key: String, view: UIView)]()
    private var reusableNodeViews = [(key: String, view: UIView)]()
    private var registeredNodeViews = [String: Any]()
    
    public var contentProvider: SwiftTickerProviderProtocol?
    public var viewProvider: SwiftTickerViewProvider?
    public weak var tickerDelegate: SwiftTickerDelegate?
    
    @IBOutlet public weak var button: UIButton!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        setupOpenGl()
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    public func start() {
        tickerDelegate?.tickerView(willStart: self)
        if isRunning {
            renewDisplayLink()
        } else {
            resume()
        }
    }
    
    public func stop() {
        guard isRunning else {
            return
        }
        
        tickerDelegate?.tickerView(willStop: self)
        isRunning = false
        displayLink?.isPaused = true
    }
    
    public func registerView(for separator: UIView.Type) {
        separatorView = separator
    }
    
    public func registerNib(for separator: UINib) {
        separatorNib = separator
    }
    
    public func registerNodeView(_ nodeView: UIView.Type, for identifier: String) {
        registeredNodeViews[identifier] = nodeView
    }
    
    public func registerNodeViewNib(_ nodeView: UINib, for identifier: String) {
        registeredNodeViews[identifier] = nodeView
    }
    
    public func dequeueReusableSeparator() -> UIView? {
        if let separator = separator {
            if let index = reusableSeparatorViews.index(where: { $0.key == separatorIdentifier }) {
                let view = reusableSeparatorViews[index].view
                reusableSeparatorViews.remove(at: index)
                return view
            }
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            label.text = separator
            label.numberOfLines = 1
            label.sizeToFit()
            return label
        } else if let separatorView = separatorView {
            return separatorView.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        } else if let separatorNib = separatorNib {
            return separatorNib.instantiate(withOwner: nil, options: nil).first as? UIView
        }
        return nil
    }
    
    public func dequeReusableNodeView(for identifier: String) -> UIView? {
        if let index = reusableNodeViews.index(where: { $0.key == identifier }) {
            let view = reusableNodeViews[index].view
            reusableNodeViews.remove(at: index)
            return view
        }
        
        guard let any = registeredNodeViews[identifier] else {
            return nil
        }
        
        if let anyclass = any as? UIView.Type {
            return anyclass.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        } else if let nib = any as? UINib {
            return nib.instantiate(withOwner: nil, options: nil).first as? UIView
        }
        
        return nil
    }
    
    //MARK: - Private
    
    private func setupOpenGl() {
        guard let context = EAGLContext(api: .openGLES2) else {
            assertionFailure("EAGL context couldn't be loaded")
            return
        }
        self.context = context
        drawableColorFormat = .RGBA8888
        EAGLContext.setCurrent(self.context)
        enableSetNeedsDisplay = true
        setNeedsDisplay()
    }
    
    private func setupUI() {
        self.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(application(didBecomeActive:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(application(willResignActive:)),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)
        
        if button == nil {
            let button = UIButton(frame: bounds)
            addSubview(button)
            self.button = button
        }
        
        button.addTarget(self,
                         action: #selector(button(touchedDown:)),
                         for: .touchDown)
        button.addTarget(self,
                         action: #selector(button(touchedUpInside:with:)),
                         for: .touchUpInside)
        button.addTarget(self,
                         action: #selector(button(touchedUpOutside:)),
                         for: .touchUpOutside)
    }
    
    @objc private func application(willResignActive application: UIApplication) {
        stop()
    }
    
    @objc private func application(didBecomeActive application: UIApplication) {
        start()
    }
    
    @objc private func button(touchedDown button: UIButton) {
        stop()
    }
    
    @objc private func button(touchedUpInside button: UIButton, with event: UIEvent) {
        guard let origin = event.allTouches?.first?.location(in: self) else {
            return
        }
        let rect = CGRect(origin: origin, size: CGSize(width: 1, height: 1))
        if let view = nodeViews.first(where: {
            $0.key != separatorIdentifier && $0.view.frame.intersects(rect)
        }) {
          tickerDelegate?.tickerView(didPress: view.view, content: view.content)
        }
        start()
    }
    
    @objc private func button(touchedUpOutside button: UIButton) {
        resume()
    }
    
    private func renewDisplayLink() {
        guard displayLink == nil else {
            displayLink?.isPaused = false
            return
        }
        
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(render))
        if #available(iOS 10.0, tvOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = interval
        } else {
            displayLink?.frameInterval = interval
        }
        displayLink?.add(to: RunLoop.current, forMode:.commonModes)
    }
    
    private func resume() {
        guard !isRunning,
            let contentProvider = contentProvider,
            contentProvider.hasContent else { return }
        
        tickerDelegate?.tickerView(willResume: self)
        isRunning = true
        
        renewDisplayLink()
    }
    
    @objc private func render() {
        guard isRunning else {
            return
        }
        
        display()
    }
    
    private func update(node: UIView, offset: CGFloat) {
        var frame = node.frame
        switch direction {
        case .horizontalRightToLeft:
            frame.origin.x -= offset
        case .horizontalLeftToRight:
            frame.origin.x += offset
        case .verticalBottomToTop:
            frame.origin.y -= offset
        case .verticalTopToBottom:
            frame.origin.y += offset
        }
        node.frame = frame
    }
    
    private func viewIsOutOfBounds(_ nodeView: UIView?) -> Bool {
        guard let nodeView = nodeView else {
            return false
        }
        
        switch direction {
        case .horizontalRightToLeft:
            return nodeView.frame.maxX < 0
        case .horizontalLeftToRight:
            return nodeView.frame.minX > frame.maxX
        case .verticalBottomToTop:
            return nodeView.frame.maxY < 0
        case .verticalTopToBottom:
            return nodeView.frame.minY > frame.maxY
        }
    }
    
    private var shouldAddView: Bool {
        guard let nodeView = nodeViews.last else {
            return true
        }
        
        switch direction {
        case .horizontalRightToLeft:
            return frame.width - nodeView.view.frame.maxX > distanceBetweenNodes
        case .horizontalLeftToRight:
            return nodeView.view.frame.minX > distanceBetweenNodes
        case .verticalBottomToTop:
            return frame.height - nodeView.view.frame.maxY > distanceBetweenNodes
        case .verticalTopToBottom:
            return nodeView.view.frame.minY > distanceBetweenNodes
        }
    }
    
    private func removeNodeIfNeeded(_ nodeView: UIView?) {
        guard let nodeView = nodeView else { return }
        
        if viewIsOutOfBounds(nodeView),
            let index = nodeViews.index(where: { $0.view === nodeView }) {
            let nodeView = nodeViews[index]
            if nodeView.key == separatorIdentifier {
                reusableSeparatorViews.append((nodeView.key, nodeView.view))
            } else if nodeView.key != dontReuseIdentifier {
                reusableNodeViews.append((nodeView.key, nodeView.view))
            }
            nodeViews.remove(at: index)
            nodeView.view.removeFromSuperview()
        }
    }
    
    private func addNewNodeIfNeeded() {
        if shouldAddView {
            addNode()
        }
    }
    
    private func addNode() {
        guard isRunning else {
            return
        }
        
        if lastNodeWasSeparator {
            lastNodeWasSeparator = false
        } else {
            lastNodeWasSeparator = true
            let separator = dequeueReusableSeparator()
            if let separator = separator {
                viewProvider?.tickerView(self, prepareSeparator: separator)
                addNode(separator,
                        for: separatorIdentifier,
                        content: nil)
            }
            return
        }
        
        if let content = contentProvider?.next,
            let nodeView = viewProvider?.tickerView(self, viewFor: content) {
            addNode(nodeView.0,
                    for: nodeView.reuseIdentifier ?? dontReuseIdentifier,
                    content: content)
        }
    }
    
    private func addNode(_ nodeView: UIView?, for identifier: String, content: Any?) {
        guard let nodeView = nodeView else {
            return
        }
        
        addSubview(nodeView)
        align(next: nodeView)
        nodeViews.append((identifier, nodeView, content))
    }
    
    private func align(next nodeView: UIView) {
        var frame = nodeView.frame
        switch direction {
        case .horizontalRightToLeft:
            if let last = nodeViews.last?.view {
                frame.origin.x = last.frame.maxX + distanceBetweenNodes
            } else {
                frame.origin.x = self.frame.maxX
            }
            frame.origin.y = (self.frame.height - nodeView.frame.height) / 2
        case .horizontalLeftToRight:
            if let last = nodeViews.last?.view {
                frame.origin.x = last.frame.minX - distanceBetweenNodes - frame.width
            } else {
                frame.origin.x = -frame.width
            }
            frame.origin.y = (self.frame.height - nodeView.frame.height) / 2
        case .verticalBottomToTop:
            if let last = nodeViews.last?.view {
                frame.origin.y = last.frame.maxY + distanceBetweenNodes
            } else {
                frame.origin.y = frame.maxY
            }
            frame.origin.x = (self.frame.width - nodeView.frame.width) / 2
        case .verticalTopToBottom:
            if let last = nodeViews.last?.view {
                frame.origin.y = last.frame.minY - distanceBetweenNodes - frame.height
            } else {
                frame.origin.y = -frame.height
            }
            frame.origin.x = (self.frame.width - nodeView.frame.width) / 2
        }
        nodeView.frame = frame
    }
    
    private var framesPerSecond: Int {
        guard let displayLink = displayLink,
            displayLink.duration > 0 else {
            return 0
        }
        return Int(round(1000 / displayLink.duration)/1000)
    }
    
    fileprivate func updateTickerNodeViewPosition() {
        let offset = pixelPerSecond / CGFloat(framesPerSecond)
        nodeViews.forEach({[weak self] in
            self?.update(node: $0.view, offset: offset)
        })
        
        removeNodeIfNeeded(nodeViews.first?.view)
        addNewNodeIfNeeded()
    }
}

extension SwiftTickerView: GLKViewDelegate {
    public func glkView(_ view: GLKView, drawIn rect: CGRect) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        backgroundColor?.getRed(&r,
                                green: &g,
                                blue: &b,
                                alpha: &a)
        
        
        glClearColor(GLfloat(r),
                     GLfloat(g),
                     GLfloat(b),
                     GLfloat(a))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        
        updateTickerNodeViewPosition()
    }
}
