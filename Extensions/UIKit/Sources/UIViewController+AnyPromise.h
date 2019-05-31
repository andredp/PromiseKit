#import <PromiseKit6/PromiseKit6.h>
#import <UIKit/UIViewController.h>

/**
 To import the `UIViewController` category:

    use_frameworks!
    pod "PromiseKit6/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit6"

 And then in your sources:

    @import PromiseKit6;
*/
@interface UIViewController (PromiseKit6)

/**
 Presents a view controller modally.

 If the view controller is one of the following:

  - MFMailComposeViewController
  - MFMessageComposeViewController
  - UIImagePickerController
  - SLComposeViewController

 Then PromiseKit6 presents the view controller returning a promise that is
 resolved as per the documentation for those classes. Eg. if you present a
 `UIImagePickerController` the view controller will be presented for you
 and the returned promise will resolve with the media the user selected.

     [self promiseViewController:[MFMailComposeViewController new] animated:YES
 completion:nil].then(^{
         //…
     });

 Otherwise PromiseKit6 expects your view controller to implement a
 `promise` property. This promise will be returned from this method and
 presentation and dismissal of the presented view controller will be
 managed for you.

     \@interface MyViewController: UIViewController
     @property (readonly) AnyPromise *promise;
     @end

     @implementation MyViewController {
         PMKResolver resolve;
     }

     - (void)viewDidLoad {
         _promise = [[AnyPromise alloc] initWithResolver:&resolve];
     }

     - (void)later {
         resolve(@"some fulfilled value");
     }

     @end

     [self promiseViewController:[MyViewController new] aniamted:YES completion:nil].then(^(id
 value){
         // value == @"some fulfilled value"
     });

 @return A promise that can be resolved by the presented view controller.
*/
- (AnyPromise *)promiseViewController:(UIViewController *)vc
                             animated:(BOOL)animated
                           completion:(void (^)(void))block NS_REFINED_FOR_SWIFT;

@end
