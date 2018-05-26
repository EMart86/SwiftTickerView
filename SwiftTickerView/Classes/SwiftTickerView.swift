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

public protocol SwiftTickerItemDecorator { }

open class SwiftTickerView: GLKView {
    private let separatorIdentifier = "SeparatorIdentifier"
    private let dontReuseIdentifier = "DontReuseIdentifier"
    
    public enum Decorator: SwiftTickerItemDecorator {
        case ignoreFirstSeparator
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
        switch decorator {
        case .ignoreFirstSeparator:
            if !isRunning {
                lastNodeWasSeparator = true
            }
        }
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

open class Renderer: SwiftTickerContentRenderer {
    public typealias ShouldAddNewNode = ((UIView, SwiftTickerView, CGFloat) -> Bool)
    public typealias ShouldRemoveNode = ((UIView, SwiftTickerView) -> Bool)
    
    /**
     Add inital render decorator for customizing the initial position of the node content
     
     - Parameter initial: Must conform to the InitialRenderer and SwiftTickerItemDecorator protocol
     */
    open func customize(with initial: SwiftTickerItemDecorator & InitialRenderer) -> Renderer {
        initials.append(initial)
        return self
    }
    
    /**
     Add update render decorator for customizing the updated position of the node content
     
     - Parameter update: Must conform to the UpdateRenderer and SwiftTickerItemDecorator protocol
     */
    open func customize(with update: SwiftTickerItemDecorator & UpdateRenderer) -> Renderer {
        updates.append(update)
        return self
    }
    
    /**
     Renders the content from right to left and centered vertically in the ticker view, starting at the right border.
     */
    public static var rightToLeft = Renderer(initials: [SwiftTickerItemDecorators.alignItemsLeftToEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtRightOuterBorder(),
                                                        SwiftTickerItemDecorators.centerVertical()],
                                             updates: [SwiftTickerItemDecorators.updateX(-)],
                                             shouldAddNewNode: { current, tickerView, offset in
                                                tickerView.frame.width - current.frame.maxX > offset
    }, shouldRemoveNode: { current, _ in
        current.frame.maxX < 0
    })
    
    /**
     Renders the content from left to right and centered vertically in the ticker view, starting at the left border.
     */
    public static var leftToRight = Renderer(initials: [SwiftTickerItemDecorators.alignItemsRightToEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtLeftOuterBorder(),
                                                        SwiftTickerItemDecorators.centerVertical()],
                                             updates: [SwiftTickerItemDecorators.updateX(+)],
                                             shouldAddNewNode: { current, _, offset in
                                                current.frame.minX > offset
    }, shouldRemoveNode: { current, tickerView in
        current.frame.minX > tickerView.frame.maxX
    })
    
    /**
     Renders the content bottom to top and centered horizontally in the ticker view, starting at the bottom border.
     */
    public static var bottomToTop = Renderer(initials: [SwiftTickerItemDecorators.alignItemsBelowEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtBottomOuterBorder(),
                                                        SwiftTickerItemDecorators.centerHorizontal()],
                                             updates: [SwiftTickerItemDecorators.updateY(-)],
                                             shouldAddNewNode: { current, tickerView, offset in
                                                tickerView.frame.height - current.frame.maxY > offset
    }, shouldRemoveNode: { current, _ in
        current.frame.maxY < 0
    })
    
    /**
     Renders the content top to bottom and centered horizontally in the ticker view, starting at the top border.
     */
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
    
    /**
     Renderer constructor
     
     - Parameter initials: An array of InitialRenderer and SwiftTickerItemDecorator for defining the start position of each ticker node view
     - Parameter updates: An array of UpdateRenderer and SwiftTickerItemDecorator for defining the updated position of each ticker node view
     - Parameter shouldAddNewNode: Closure if a new node view should be added
     - Parameter shouldRemoveNode: Closure if a given new node view should be removed
     */
    public init(initials: [InitialRenderer & SwiftTickerItemDecorator],
                updates: [UpdateRenderer & SwiftTickerItemDecorator],
                shouldAddNewNode: @escaping ShouldAddNewNode,
                shouldRemoveNode: @escaping ShouldRemoveNode) {
        self.initials = initials
        self.updates = updates
        self.shouldAddNewNode = shouldAddNewNode
        self.shouldRemoveNode = shouldRemoveNode
    }
    
    open func tickerViewUpdate(_ tickerView: SwiftTickerView, render nodeView: UIView, offset: CGFloat) {
        updates.forEach { $0.updateWith(current: nodeView, offset: offset) }
    }
    
    open func tickerViewShouldAddNext(_ tickerView: SwiftTickerView, current nodeView: UIView) -> Bool {
        return shouldAddNewNode(nodeView, tickerView, tickerView.distanceBetweenNodes)
    }
    
    open func tickerViewShouldRemove(_ tickerView: SwiftTickerView, nodeView: UIView) -> Bool {
        return shouldRemoveNode(nodeView, tickerView)
    }
    
    open func tickerView(_ tickerView: SwiftTickerView, render nodeView: UIView, with identifier: String) {
        initials.forEach {
            $0.updateWith(current: nodeView,
                          last: last?.superview != nil ? last : nil,
                          tickerView: tickerView,
                          offset: tickerView.distanceBetweenNodes) }
        last = nodeView
    }
}

public struct SwiftTickerItemDecorators {
    /**
     InitialRenderer
     
     Aligns the items left to each other
     
     This is used in the rightToLeft Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    public static func alignItemsLeftToEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.x = last.frame.maxX + (customOffset ?? offset)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items right to each other
     
     This is used in the leftToRight Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    
    public static func alignItemsRightToEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.x = last.frame.minX - (customOffset ?? offset) - frame.width
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items below each other
     
     This is used in the bottomToTop Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    
    public static func alignItemsBelowEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.y = last.frame.maxY + (customOffset ?? offset)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items above each other
     
     This is used in the topToBottom Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    
    public static func alignItemsAboveEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.y = last.frame.minY - (customOffset ?? offset) - frame.height
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the right border so that it is not visible in the beginning
     
     This is used in the rightToLeft Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtRightOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = tickerView.frame.maxX + (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the right border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtRightInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = tickerView.frame.maxX - frame.width - (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the left border so that it is not visible in the beginning
     
     This is used in the leftToRight Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtLeftOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = -frame.width - (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the left border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtLeftInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = customOffset ?? 0
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the bottom border so that it is not visible in the beginning
     
     This is used in the bottomToTop Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtBottomOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = tickerView.frame.maxY + (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the left border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtBottomInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = tickerView.frame.height - frame.height - (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the top border so that it is not visible in the beginning
     
     This is used in the topToBottom Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtTopOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = -frame.height + (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at top border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtTopInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = customOffset ?? 0
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items vertically centered in the view
     
     This is used in the leftToRight and rightToLeft Rendering option
     
     - Parameter customOffset: A custom offset from the vertical center
     */
    public static func centerVertical(with offset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.y = ((tickerView.frame.height - frame.height) / 2) + (offset ?? 0)
                current.frame = frame
            }
            
            init(offset: CGFloat? = nil) {
                self.offset = offset
            }
            
            let offset: CGFloat?
        }
        return Anonymous(offset: offset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items horizontally centered in the view
     
     This is used in the topToBottom and bottomToTop Rendering option
     
     - Parameter customOffset: A custom offset from the horizontal center
     */
    public static func centerHorizontal(with offset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.x = ((tickerView.frame.width - frame.width) / 2) + (offset ?? 0)
                current.frame = frame
            }
            
            init(offset: CGFloat? = nil) {
                self.offset = offset
            }
            
            let offset: CGFloat?
        }
        return Anonymous(offset: offset)
    }
    
    /**
     UpdateRenderer
     
     Updates the x position of the view
     
     This is used in the leftToRight and rightToLeft Rendering option
     
     - Parameter function: Use an oparator eg (+, -, *, /,...)
     */
    public static func updateX(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) -> SwiftTickerItemDecorator & UpdateRenderer {
        struct Anonymous: SwiftTickerItemDecorator, UpdateRenderer {
            func updateWith(current: UIView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.x = function(frame.origin.x, offset)
                current.frame = frame
            }
            
            init(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) {
                self.function = function
            }
            
            let function: (CGFloat, CGFloat) -> CGFloat
        }
        return Anonymous(function)
    }
    
    /**
     UpdateRenderer
     
     Updates the y position of the view
     
     This is used in the topToBottom and bottomToTop Rendering option
     
     - Parameter function: Use an oparator eg (+, -, *, /,...)
     */
    public static func updateY(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) -> SwiftTickerItemDecorator & UpdateRenderer {
        struct Anonymous: SwiftTickerItemDecorator, UpdateRenderer {
            func updateWith(current: UIView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.y = function(frame.origin.y, offset)
                current.frame = frame
            }
            
            init(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) {
                self.function = function
            }
            
            let function: (CGFloat, CGFloat) -> CGFloat
        }
        return Anonymous(function)
    }
}
