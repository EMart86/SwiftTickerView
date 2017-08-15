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
    
    func tickerView(_ tickerView: SwiftTickerView, viewFor: Any) -> UIView
}

public final class SwiftTickerView: GLKView {
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
    
    public var frameInterval: Int = 1 {
        didSet {
            if #available(iOS 10.0, *) {
                displayLink?.preferredFramesPerSecond = frameInterval / 10
            } else {
                displayLink?.frameInterval = frameInterval
            }
        }
    }
    public var separator: String?
    public var distanceBetweenNodes: CGFloat = 8
    public var tickerDelegate: SwiftTickerDelegate?
    public var provider: SwiftTickerProviderProtocol?
    public private(set) var isRunning = false
    
    private var lastNodeWasSeparator: Bool = false
    private var displayLink: CADisplayLink?
    private var nodeViews = [UIView]()
    
    @IBOutlet weak var button: UIButton!
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame,
                   context: EAGLContext(api: .openGLES2))
        
        setupUI()
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        tickerDelegate?.tickerView(willStart: self)
        renewDisplayLink()
    }
    
    public func stop() {
        guard isRunning else {
            return
        }
        
        tickerDelegate?.tickerView(willStop: self)
        isRunning = false
        displayLink?.remove(from: RunLoop.current, forMode: .commonModes)
        displayLink = nil
    }
    
    //MARK: - Private
    
    private func setupUI() {
        self.delegate = self
        enableSetNeedsDisplay = false
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(application(didBecomeActive:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(application(willResignActive:)),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)
        
        if button == nil {
            button = UIButton(type: .custom)
            button.frame = bounds
            addSubview(button)
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
        
    }
    
    @objc private func button(touchedUpOutside button: UIButton) {
        resume()
    }
    
    private func renewDisplayLink() {
        guard displayLink == nil else { return }
        
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(render))
        displayLink?.frameInterval = frameInterval
        displayLink?.add(to: RunLoop.current, forMode:.commonModes)
    }
    
    private func resume() {
        guard !isRunning,
            let provider = provider,
            provider.hasContent else { return }
        
        tickerDelegate?.tickerView(willResume: self)
        isRunning = true
        
        renewDisplayLink()
    }
    
    @objc private func render() {
        guard isRunning else {
            return
        }
        
        render()
    }
    
    private func update(node: UIView) {
        var frame = node.frame
        switch direction {
        case .horizontalRightToLeft:
            frame.origin.x -= 1
        case .horizontalLeftToRight:
            frame.origin.x += 1
        case .verticalBottomToTop:
            frame.origin.y -= 1
        case .verticalTopToBottom:
            frame.origin.y += 1
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
            return frame.width - nodeView.frame.maxX > distanceBetweenNodes
        case .horizontalLeftToRight:
            return nodeView.frame.minX > distanceBetweenNodes
        case .verticalBottomToTop:
            return frame.height - nodeView.frame.maxY > distanceBetweenNodes
        case .verticalTopToBottom:
            return nodeView.frame.minY > distanceBetweenNodes
        }
    }
    
    private func removeNodeIfNeeded(_ nodeView: UIView?) {
        guard let nodeView = nodeView else { return }
        
        if viewIsOutOfBounds(nodeView),
            let index = nodeViews.index(of: nodeView) {
            nodeViews.remove(at: index)
            nodeView.removeFromSuperview()
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
        
        if let separator = separator {
            if lastNodeWasSeparator {
                lastNodeWasSeparator = false
            } else {
                lastNodeWasSeparator = true
                addNode(tickerDelegate?.tickerView(self, viewFor: separator))
            }
        }
        
        if let content = provider?.next {
            addNode(tickerDelegate?.tickerView(self, viewFor: content))
        }
    }
    
    private func addNode(_ nodeView: UIView?) {
        guard let nodeView = nodeView else {
            return
        }
        
        addSubview(nodeView)
        align(next: nodeView)
    }
    
    private func align(next nodeView: UIView) {
        var frame = nodeView.frame
        switch direction {
        case .horizontalRightToLeft:
            if let last = nodeViews.last {
                frame.origin.x = last.frame.maxX + distanceBetweenNodes
            } else {
                frame.origin.x = frame.maxX
            }
        case .horizontalLeftToRight:
            if let last = nodeViews.last {
                frame.origin.x = last.frame.minX - distanceBetweenNodes
            } else {
                frame.origin.x = 0
            }
        case .verticalBottomToTop:
            if let last = nodeViews.last {
                frame.origin.y = last.frame.maxY + distanceBetweenNodes
            } else {
                frame.origin.y = frame.maxY
            }
        case .verticalTopToBottom:
            if let last = nodeViews.last {
                frame.origin.y = last.frame.minY - distanceBetweenNodes
            } else {
                frame.origin.y = 0
            }
        }
        nodeView.frame = frame
    }
    
    fileprivate func updateTickerNodeViewPosition() {
        guard !nodeViews.isEmpty else {
            return
        }
        
        nodeViews.forEach({[weak self] in
            self?.update(node: $0)
        })
            
        removeNodeIfNeeded(nodeViews.first)
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
        
        updateTickerNodeViewPosition()
    }
}
