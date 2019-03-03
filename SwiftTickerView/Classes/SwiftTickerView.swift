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
//    func tickerViewDidStartDragging(_ ticker: SwiftTickerView)
//    func tickerViewDidEndDragging(_ ticker: SwiftTickerView)
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

public protocol Condition {
    func meets(nodeView: UIView, tickerView: SwiftTickerView) -> Bool
}

public enum ReturnBehavior {
    case `continue`
    case `return`
    case `break`
}

public typealias Action = (Renderer, SwiftTickerView) -> ReturnBehavior

public protocol SwiftTickerItemDecorator { }

open class SwiftTickerView: GLKView {
    private let separatorIdentifier = "SeparatorIdentifier"
    private let dontReuseIdentifier = "DontReuseIdentifier"
    
    public enum Decorator: SwiftTickerItemDecorator {
        case ignoreFirstSeparator
        case draggingEnabled
    }
    
    private var isDragging = false {
        didSet {
            guard oldValue != isDragging else {
                return
            }
            if isDragging {
                wasRunningBeforeDragging = isRunning
                stop()
//                tickerDelegate?.tickerViewDidStartDragging(self)
            } else {
                if wasRunningBeforeDragging {
                    resume()
                }
//                tickerDelegate?.tickerViewDidEndDragging(self)
            }
        }
    }
    
    private var decorators = [Decorator]()
    
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
    
    /**
     Assign a custom renderer to allow the content to be rendered on the ticker view.
     Default is rightToLeft
     */
    public var render: SwiftTickerContentRenderer = Renderer.rightToLeft {
        didSet {
            guard isRunning else {
                return
            }
            stop()
            resume()
        }
    }
    
    /**
     Set a custom pixelPerSeconds to increase or decrease the update interval of the content.
     Default is 60
     WARNING: The more you increase this value, the more it looks stuttering
     */
    public var pixelPerSecond: CGFloat = 60 {
        didSet {
            guard pixelPerSecond > 0 else {
                stop()
                return
            }
            renewDisplayLink()
        }
    }
    
    /**
     Asign a custom separator
     */
    public var separator: String?
    private var separatorView: UIView.Type?
    private var separatorNib: UINib?
    
    /**
     Use this as offset between the items rendered on the ticker view
     Default is 8 pixel
     */
    public var distanceBetweenNodes: CGFloat = 8
    
    /**
     Determine if the tickerview is rendering the content or has been stopped
     */
    private var wasRunningBeforeDragging = false
    public private(set) var isRunning = false
    
    private var lastNodeWasSeparator = false
    private var displayLink: CADisplayLink?
    private var nodeViews = [(key: String, view: UIView, content: Any?)]()
    private var reusableSeparatorViews = [(key: String, view: UIView)]()
    private var reusableNodeViews = [(key: String, view: UIView)]()
    private var registeredNodeViews = [String: Any]()
    
    /**
     Asign a custom content provider.
     */
    public var contentProvider: SwiftTickerProviderProtocol?
    /**
     Asign a custom view provider
     */
    public var viewProvider: SwiftTickerViewProvider?
    /**
     Asign a custom delegate
     */
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
    
    /**
     Adds a decorator to the tickerview
     
     - Parameter decorator: a protocol to customize the view behavior
     */
    open func add(decorator: Decorator) {
        guard !decorators.contains(decorator) else {
            return
        }
        
        decorators.append(decorator)
        apply(decorator: decorator)
    }
    
    /**
     Starts the ticker view rendering
     */
    open func start() {
        tickerDelegate?.tickerView(willStart: self)
        if isRunning {
            renewDisplayLink()
        } else {
            resume()
        }
    }
    
    /**
     Stops the ticker from rendering the content
     */
    open func stop() {
        guard isRunning else {
            return
        }
        
        tickerDelegate?.tickerView(willStop: self)
        isRunning = false
        displayLink?.isPaused = true
    }
    
    /**
     Sets a custom separator view that will be created during runtime
     
     - Parameter separator: custom separator view type
     */
    open func registerView(for separator: UIView.Type) {
        separatorView = separator
    }
    
    /**
     Sets a separator nip that will be created during runtime
     
     - Parameter separator: custom separator nib
     */
    open func registerNib(for separator: UINib) {
        separatorNib = separator
    }
    
    /**
     Register a nodeview view type for a specific identifier, that can be dequed during runtime
     
     - Parameter nodeView: custom node view type
     
     - Parameter identifier: reused identifier
     */
    open func registerNodeView(_ nodeView: UIView.Type, for identifier: String) {
        registeredNodeViews[identifier] = nodeView
    }
    
    /**
     Register a nodeview view nib for a specific identifier, that can be dequed during runtime
     
     - Parameter nodeView: custom node view nib
     
     - Parameter identifier: reused identifier
     */
    open func registerNodeViewNib(_ nodeView: UINib, for identifier: String) {
        registeredNodeViews[identifier] = nodeView
    }
    
    /**
     Returns a dequed separator. If there is nothing to deque and a 'separator' e.g. '+++' is given, a label is being instantiated of if a 'separatorView' type is given, it will be instantiated of if a 'separatorNib' is given, the nib will be instantiated
     
     - Return: dequed or created separator view
     */
    open func dequeueReusableSeparator() -> UIView? {
        if let index = reusableSeparatorViews.index(where: { $0.key == separatorIdentifier }) {
            let view = reusableSeparatorViews[index].view
            reusableSeparatorViews.remove(at: index)
            return view
        } else if let separator = separator {
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
    
    /**
     Returns a dequed node view by the given identifier. If there is nothing to deque and a 'nodeView' type is given, it will be instantiated of if a nib is given, the nib will be instantiated
     
     - Return: dequed or created separator view
     */
    open func dequeReusableNodeView(for identifier: String) -> UIView? {
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
    
    /**
     Clears all nodes from the ticker view. If the view is still running, it will instantly start to render the content if provided
     
     WARNING: use carefully. If the ticker view is still running, this may look edgy
     */
    open func reloadData() {
        nodeViews.forEach {
            removeNode($0.view)
        }
        decorators.forEach { [weak self] decorator in
            self?.apply(decorator: decorator)
        }
        while addNewNodeIfNeeded() {
        }
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
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(application(willResignActive:)),
                                               name: UIApplication.willResignActiveNotification,
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
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: #selector(panDetected(_:)))
        button.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func panDetected(_ sender: UIPanGestureRecognizer) {
        if !isDragging {
            isDragging = true
        }
//        
//        switch sender.state {
//        case .changed:
//            let velocity = sender.velocity(in: self)
//        case .ended:
//        }
//        
        
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
        isDragging = false
    }
    
    private func renewDisplayLink() {
        guard pixelPerSecond > 0 else {
            return
        }
        guard displayLink == nil else {
            displayLink?.isPaused = false
            if #available(iOS 10.0, tvOS 10.0, *) {
                displayLink?.preferredFramesPerSecond = Int(pixelPerSecond)
            } else {
                displayLink?.frameInterval = Int(pixelPerSecond/60)
            }
            return
        }
        
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(rendering))
        if #available(iOS 10.0, tvOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = Int(pixelPerSecond)
        } else {
            displayLink?.frameInterval = Int(pixelPerSecond/60)
        }
        displayLink?.add(to: .main, forMode: RunLoop.Mode.common)
    }
    
    private func apply(decorator: Decorator) {
        switch decorator {
        case .ignoreFirstSeparator:
            if !isRunning {
                lastNodeWasSeparator = true
            }
        case .draggingEnabled:
            break
        }
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
        
        if viewIsOutOfBounds(nodeView) {
            removeNode(nodeView)
        }
    }
    
    private func removeNode(_ nodeView: UIView) {
        if let index = nodeViews.index(where: { $0.view === nodeView }) {
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
    
    private func addNewNodeIfNeeded() -> Bool {
        guard shouldAddView else {
            return false
        }
        addNode()
        return true
    }
    
    private var hasSepatator: Bool {
        return separator != nil || separatorNib != nil || separatorView != nil
    }
    
    private func addNode() {
        if hasSepatator && !lastNodeWasSeparator {
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
        lastNodeWasSeparator = false
        
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
        guard offset != CGFloat.infinity, offset != -CGFloat.infinity else {
            return
        }
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
