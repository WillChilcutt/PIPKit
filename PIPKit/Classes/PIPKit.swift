import Foundation
import UIKit

public enum PIPState {
    case pip
    case full
}

enum _PIPState {
    case none
    case pip
    case full
    case exit
}

public enum PIPPosition {
    case topLeft
    case middleLeft
    case bottomLeft
    case topRight
    case middleRight
    case bottomRight
    
    func isHorizontalRelativeTo(otherPosition : PIPPosition) -> Bool
    {
        return self.horizontalOpposite() == otherPosition
    }
    
    func isVerticalRelativeTo(otherPosition : PIPPosition) -> Bool
    {
        let leftSide : [PIPPosition] = [.topLeft,.middleLeft,.bottomLeft]
        let rightSide : [PIPPosition] = [.topRight,.middleRight,.bottomRight]
        
        if leftSide.contains(self) == true && leftSide.contains(otherPosition) == true
        {
            return true
        }
        else if rightSide.contains(self) == true && rightSide.contains(otherPosition) == true
        {
            return true
        }
        
        return false
    }
    
    func verticalOpposite() -> PIPPosition
    {
        switch self
        {
            case .topLeft:
                return .bottomLeft
            case .topRight:
                return .bottomRight
            case .bottomLeft:
                return .topLeft
            case .bottomRight:
                return .topRight
            default:
                return self
        }
    }
    
    func horizontalOpposite() -> PIPPosition
    {
        switch self
        {
            case .topLeft:
                return .topRight
            case .topRight:
                return .topLeft
            case .middleLeft:
                return .middleRight
            case .middleRight:
                return .middleLeft
            case .bottomLeft:
                return .bottomRight
            case .bottomRight:
                return .bottomLeft
        }
    }
    
    func isMiddlePosition() -> Bool
    {
        return [PIPPosition.middleLeft,PIPPosition.middleRight].contains(self)
    }
}

public typealias PIPKitViewController = (UIViewController & PIPUsable)

public final class PIPKit {
    
    static public var isActive: Bool { return rootViewController != nil }
    static public var isPIP: Bool { return state == .pip }
    static public var visibleViewController: PIPKitViewController? { return rootViewController }
    static public var allowedPIPPositions : [PIPPosition] = [.topLeft, .topRight, .middleLeft, .middleRight, .bottomLeft, .bottomRight]
    
    static public var defaultPIPPosition : PIPPosition = .bottomRight
    static internal var state: _PIPState = .none
    static private var rootViewController: PIPKitViewController?
    
    public class func show(with viewController: PIPKitViewController, completion: (() -> Void)? = nil) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        guard !isActive else {
            dismiss(animated: false) {
                PIPKit.show(with: viewController)
            }
            return
        }
        
        rootViewController = viewController
        state = (viewController.initialState == .pip) ? .pip : .full
        
        viewController.view.alpha = 0.0
        window.addSubview(viewController.view)
        viewController.setupEventDispatcher()
        
        UIView.animate(withDuration: 0.25, animations: {
            PIPKit.rootViewController?.view.alpha = 1.0
        }) { (_) in
            completion?()
        }
    }
    
    public class func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        state = .exit
        rootViewController?.pipDismiss(animated: animated, completion: {
            PIPKit.reset()
            completion?()
        })
    }
    
    // MARK: - Internal
    class func startPIPMode() {
        guard let rootViewController = rootViewController else {
            return
        }
        
        // PIP
        state = .pip
        rootViewController.pipEventDispatcher?.enterPIP()
    }
    
    class func stopPIPMode() {
        guard let rootViewController = rootViewController else {
            return
        }
        
        // fullScreen
        state = .full
        rootViewController.pipEventDispatcher?.enterFullScreen()
    }
    
    // MARK: - Private
    private static func reset() {
        PIPKit.state = .none
        PIPKit.rootViewController = nil
    }
    
}
