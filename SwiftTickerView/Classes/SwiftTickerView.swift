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

public protocol SwiftTickerContentRenderer {
    func tickerView(_ tickerView: SwiftTickerView, render nodeView: UIView, with identifier: String)
    func tickerViewUpdate(_ tickerView: SwiftTickerView, render nodeView: UIView, offset: CGFloat)
    func tickerViewShouldAddNext(_ tickerView: SwiftTickerView, current nodeView: UIView) -> Bool
    func tickerViewShouldRemove(_ tickerView: SwiftTickerView, nodeView: UIView) -> Bool
}

public protocol InitialRenderer {
    func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat)
}

public protocol UpdateRenderer {
    func updateWith(current: UIView, offset: CGFloat)
}

open class SwiftTickerView: GLKView {
    private let separatorIdentifier = "SeparatorIdentifier"
    private let dontReuseIdentifier = "DontReuseIdentifier"
    
    open class Renderer: SwiftTickerContentRenderer {
        typealias ShouldAddNewNode = ((UIView, SwiftTickerView, CGFloat) -> Bool)
        typealias ShouldRemoveNode = ((UIView, SwiftTickerView) -> Bool)
        
        public func customize(with initial: SwiftTickerItemDecorator & InitialRenderer) -> Renderer {
            initials.append(initial)
            return self
        }
        
        public func customize(with update: SwiftTickerItemDecorator & UpdateRenderer) -> Renderer {
            updates.append(update)
            return self
        }
        
        public static var rightToLeft = Renderer(initials: [SwiftTickerItemDecorators.alignItemsLeftToEachOther(),
                                                            SwiftTickerItemDecorators.prepareAtRightOuterBorder(),
                                                            SwiftTickerItemDecorators.centerVertical()],
                                                 updates: [SwiftTickerItemDecorators.updateX(-)],
                                                 shouldAddNewNode: { current, tickerView, offset in
            tickerView.frame.width - current.frame.maxX > offset
        }, shouldRemoveNode: { current, _ in
            current.frame.maxX < 0
        })
        
        public static var leftToRight = Renderer(initials: [SwiftTickerItemDecorators.alignItemsRightToEachOther(),
                                                            SwiftTickerItemDecorators.prepareAtLeftOuterBorder(),
                                                            SwiftTickerItemDecorators.centerVertical()],
                                                 updates: [SwiftTickerItemDecorators.updateX(+)],
                                                 shouldAddNewNode: { current, _, offset in
            current.frame.minX > offset
        }, shouldRemoveNode: { current, tickerView in
            current.frame.minX > tickerView.frame.maxX
        })
        
        public static var bottomToTop = Renderer(initials: [SwiftTickerItemDecorators.alignItemsBelowEachOther(),
                                                            SwiftTickerItemDecorators.prepareAtBottomOuterBorder(),
                                                            SwiftTickerItemDecorators.centerHorizontal()],
                                                 updates: [SwiftTickerItemDecorators.updateY(-)],
                                                 shouldAddNewNode: { current, tickerView, offset in
            tickerView.frame.height - current.frame.maxY > offset
        }, shouldRemoveNode: { current, _ in
            current.frame.maxY < 0
        })
        
        public static var topToBottom = Renderer(initials: [SwiftTickerItemDecorators.centerHorizontal(),
                                                            SwiftTickerItemDecorators.alignItemsAboveEachOther(),
                                                            SwiftTickerItemDecorators.prepareAtTopOuterBorder()],
                                                 updates: [SwiftTickerItemDecorators.updateY(+)],
                                                 shouldAddNewNode: { current, _, offset in
            current.frame.minY > offset
        }, shouldRemoveNode: { current, tickerView in
            current.frame.minY > tickerView.frame.maxY
        })
        
        private var initials: [InitialRenderer & SwiftTickerItemDecorator]
        private var updates: [UpdateRenderer & SwiftTickerItemDecorator]
        private let shouldAddNewNode: ShouldAddNewNode
        private let shouldRemoveNode: ShouldRemoveNode
        private var last: UIView?
        
        init(initials: [InitialRenderer & SwiftTickerItemDecorator],
             updates: [UpdateRenderer & SwiftTickerItemDecorator],
             shouldAddNewNode: @escaping ShouldAddNewNode,
             shouldRemoveNode: @escaping ShouldRemoveNode) {
            self.initials = initials
            self.updates = updates
            self.shouldAddNewNode = shouldAddNewNode
            self.shouldRemoveNode = shouldRemoveNode
        }
        
        public func tickerViewUpdate(_ tickerView: SwiftTickerView, render nodeView: UIView, offset: CGFloat) {
            updates.forEach { $0.updateWith(current: nodeView, offset: offset) }
        }
        
        public func tickerViewShouldAddNext(_ tickerView: SwiftTickerView, current nodeView: UIView) -> Bool {
            return shouldAddNewNode(nodeView, tickerView, tickerView.distanceBetweenNodes)
        }
        
        public func tickerViewShouldRemove(_ tickerView: SwiftTickerView, nodeView: UIView) -> Bool {
            return shouldRemoveNode(nodeView, tickerView)
        }
        
        public func tickerView(_ tickerView: SwiftTickerView, render nodeView: UIView, with identifier: String) {
            initials.forEach {
                $0.updateWith(current: nodeView,
                              last: last,
                              tickerView: tickerView,
                              offset: tickerView.distanceBetweenNodes) }
            last = nodeView
        }
    }
    
    @available(*, deprecated: 1.0.0, renamed: "SwiftTickerView")
    public enum Direction {
        @available(*, unavailable, renamed: "SwiftTickerView.Renderer.rightToLeft")
        case horizontalRightToLeft
        @available(*, unavailable, renamed: "SwiftTickerView.Renderer.leftToRight")
        case horizontalLeftToRight
        @available(*, unavailable, renamed: "SwiftTickerView.Renderer.topToBottom")
        case verticalTopToBottom
        @available(*, unavailable, renamed: "SwiftTickerView.Renderer.bottomToTop")
        case verticalBottomToTop
    }
    
    @available(*, unavailable, renamed: "render")
    public var direction: Direction?
    
    public var render: SwiftTickerContentRenderer = Renderer.rightToLeft {
        didSet {
            stop()
            resume()
        }
    }
    
    public var pixelPerSecond: CGFloat = 60 {
        didSet {
            renewDisplayLink()
        }
    }
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
    
    open override func awakeFromNib() {
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
        guard let context = loadEaglContext() else {
            assertionFailure("EAGL context couldn't be loaded")
            return
        }
        self.context = context
        drawableColorFormat = .RGBA8888
        EAGLContext.setCurrent(self.context)
        enableSetNeedsDisplay = true
        setNeedsDisplay()
    }
    
    private func loadEaglContext() -> EAGLContext? {
        return EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) ?? EAGLContext(api: .openGLES1)
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
            if #available(iOS 10.0, tvOS 10.0, *) {
                displayLink?.preferredFramesPerSecond = Int(pixelPerSecond)
            } else {
                displayLink?.frameInterval = Int(pixelPerSecond)
            }
            return
        }
        
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(rendering))
        if #available(iOS 10.0, tvOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = Int(pixelPerSecond)
        } else {
            displayLink?.frameInterval = Int(pixelPerSecond)
        }
        displayLink?.add(to: .main, forMode:.commonModes)
    }
    
    private func resume() {
        guard !isRunning,
            let contentProvider = contentProvider,
            contentProvider.hasContent else { return }
        
        tickerDelegate?.tickerView(willResume: self)
        isRunning = true
        
        renewDisplayLink()
    }
    
    @objc private func rendering() {
        guard isRunning else {
            return
        }
        
        display()
    }
    
    private func update(node: UIView, offset: CGFloat) {
        render.tickerViewUpdate(self, render: node, offset: offset)
    }
    
    private func viewIsOutOfBounds(_ nodeView: UIView?) -> Bool {
        guard let nodeView = nodeView else {
            return false
        }
        
        return render.tickerViewShouldRemove(self, nodeView: nodeView)
    }
    
    private var shouldAddView: Bool {
        guard let nodeView = nodeViews.last else {
            return true
        }
        
        return render.tickerViewShouldAddNext(self, current: nodeView.view)
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
        render.tickerView(self, render: nodeView, with: identifier)
        nodeViews.append((identifier, nodeView, content))
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
        nodeViews.forEach { [weak self] in
            self?.update(node: $0.view, offset: offset)
        }
        
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
