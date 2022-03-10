import SwiftUI

private struct VLPromptModifier: ViewModifier
{
 @Binding var isPresented: Bool
 @Binding var value: String
 let title: String
 let message: String?
 let placeholder: String?
 let cancelLabel: String?
 let submitLabel: String?
 let keyboardType: UIKeyboardType
 let textfieldCustomizer: ((UITextField) -> Void)?

 func body(content: Content) -> some View
 {
  if isPresented
  {
   content.overlay
   {
    VLPromptControlView(isPresented: $isPresented,
                        value: $value,
                        title: title,
                        message: message,
                        placeholder: placeholder,
                        cancelLabel: cancelLabel,
                        submitLabel: submitLabel,
                        keyboardType: keyboardType,
                        textfieldCustomizer: textfieldCustomizer)
   }
  }
  else
  {
   content
  }
 }
}

extension View
{
 func prompt(isPresented: Binding<Bool>,
             text value: Binding<String>,
             title: String,
             message: String? = nil,
             placeholder: String? = nil,
             cancelLabel: String? = nil,
             submitLabel: String? = nil,
             keyboardType: UIKeyboardType = .default,
             textfieldCustomizer: ((UITextField) -> Void)? = nil) -> some View
 {
  return self.modifier(VLPromptModifier(isPresented: isPresented,
                                        value: value,
                                        title: title,
                                        message: message,
                                        placeholder: placeholder,
                                        cancelLabel: cancelLabel,
                                        submitLabel: submitLabel,
                                        keyboardType: keyboardType,
                                        textfieldCustomizer: textfieldCustomizer))
 }
}

private struct VLPromptControlView: UIViewControllerRepresentable
{
 @Binding var isPresented: Bool
 @Binding var value: String
 let title: String
 let message: String?
 let placeholder: String?
 let cancelLabel: String?
 let submitLabel: String?
 let keyboardType: UIKeyboardType
 let textfieldCustomizer: ((UITextField) -> Void)?

 private var innerValue: String

 init(isPresented: Binding<Bool>,
      value: Binding<String>,
      title: String,
      message: String? = nil,
      placeholder: String? = nil,
      cancelLabel: String? = nil,
      submitLabel: String? = nil,
      keyboardType: UIKeyboardType = .default,
      textfieldCustomizer: ((UITextField) -> Void)? = nil)
 {
  self._isPresented = isPresented
  self._value = value
  self.title = title
  self.message = message
  self.placeholder = placeholder
  self.cancelLabel = cancelLabel
  self.submitLabel = submitLabel
  self.keyboardType = keyboardType
  self.textfieldCustomizer = textfieldCustomizer
  self.innerValue = value.wrappedValue
 }

 func makeUIViewController(context: UIViewControllerRepresentableContext<VLPromptControlView>) -> UIViewController
 {
  return UIViewController()
 }

 func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<VLPromptControlView>)
 {
  guard context.coordinator.alertController == nil else { return }

  if isPresented
  {
   let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

   context.coordinator.alertController = alertController

   alertController.addTextField
   {
    field in
    field.placeholder = placeholder ?? ""
    field.text = innerValue
    field.keyboardType = keyboardType
    textfieldCustomizer?(field)
    field.delegate = context.coordinator
   }

   alertController.addAction(UIAlertAction(title: NSLocalizedString(cancelLabel ?? "Cancel", comment: ""), style: .destructive)
                             {
                              _ in
                              alertController.dismiss(animated: !UIAccessibility.isReduceMotionEnabled)
                              {
                               isPresented = false
                              }
                             })

   alertController.addAction(UIAlertAction(title: NSLocalizedString(submitLabel ?? "Submit", comment: ""), style: .default)
                             {
                              _ in
                              if let textField = alertController.textFields?.first,
                                 let text = textField.text
                              {
                               value = text
                              }

                              alertController.dismiss(animated: !UIAccessibility.isReduceMotionEnabled)
                              {
                               isPresented = false
                              }
                              })

   DispatchQueue.main.async
   {
    uiViewController.present(alertController,
                             animated: !UIAccessibility.isReduceMotionEnabled,
                             completion:
                             {
                              isPresented = false
                              context.coordinator.alertController = nil
                             })
   }
  }
 }

 func makeCoordinator() -> VLPromptControlView.Coordinator
 {
  Coordinator(self)
 }

 final class Coordinator: NSObject, UITextFieldDelegate
 {
  var alertController: UIAlertController?
  var control: VLPromptControlView

  init(_ control: VLPromptControlView)
  {
   self.control = control
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
  {
   if let text = textField.text as NSString?
   {
    control.innerValue = text.replacingCharacters(in: range, with: string)
   }
   else
   {
    control.innerValue = ""
   }

   return true
  }
 }
}


// MARK: - Preview
#if DEBUG
struct VLPromptWrapper: View
{
 @State private var isPresentedBase: Bool = false
 @State private var isPresentedCustom: Bool = false
 @State private var textBase: String = "Minimal prompt"
 @State private var textCustom: String = "Fully custom prompt"

 var body: some View
 {
  VStack
  {
   Button(textBase) { isPresentedBase = true }
   .buttonStyle(.borderedProminent)
   .prompt(isPresented: $isPresentedBase, text: $textBase, title: "Minimal prompt title")

   Button(textCustom) { isPresentedCustom = true }
   .buttonStyle(.borderedProminent)
   .prompt(isPresented: $isPresentedCustom,
           text: $textCustom,
           title: "Fully custom title",
           message: "Secondary message",
           placeholder: "Placeholder when text is empty",
           cancelLabel: "cancel label",
           submitLabel: "submit label",
           keyboardType: .numbersAndPunctuation,
           textfieldCustomizer:
           {
            field in
            field.clearButtonMode = .always
           })
  }
 }
}

struct VLPrompt_Previews: PreviewProvider
{
 static var previews: some View
 {
  VLPromptWrapper()
 }
}
#endif
