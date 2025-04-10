## 1.3.0

###  Performance Improvement
- Reduced excessive rebuilds in GridView during scrolling

## 1.2.0

- Android example app - migrated Android Gradle Plugin from imperative to declarative syntax.
- Resolved an issue where `dragStartDelay` was not working correctly when set to 0, to enable
  instant drag in vertical scroll direction.

## 1.1.6

### Improvements

- Update documentation
- Refactor code

## 1.1.5

### Improvements

- Add `lockedItems` to make items locked and non-draggable.

### Bug Fixes

- Fix issue with `nonDraggableItems` for different instances of the list.

## 1.1.4

### Improvements

- Add swap animation when changing the order of items in the list
- Add 'enableSwap' to enable/disable swap animation
- Add 'nonDraggableItems' to make items non-draggable and enable/disable reordering
- Add `dragStartDelay` to delay the start of the drag gesture
- Deprecate 'longPressDrag' in favor of `dragStartDelay`
- Update Example App

## 1.1.3

### Bug fixes

- Fix flicker/jump issue while reordering different sized items in the list

## 1.1.2

### Enhancement

- Update readme

## 1.1.1

### Enhancement

- Improve example app

## 1.1.0

### Enhancement

- Fix shrinkwrap support

## 1.0.9

### Enhancement

- Minor changes

## 1.0.8

### Enhancements

- Add `isItemSame` callback to compare two items to determine if two items are the same. It should
  return true if the two compared items are identical.
- Add `shrinkWrap` property to allow the widget to size itself to the size of its children in the
  main axis direction.

## 1.0.7

### Bug Fixes

- List Will Not Animate When New Item Is Added to the End of the List

### Enhancement

- Allow Disabling Long Press to Start Reorder Gesture

## 1.0.6

### Bug Fixes

- Add equality check in example app to prevent animation on update of item in list.

## 1.0.5

### Bug Fixes

- Fix `onReorderEnd` callback not being called after reordering is completed.

## 1.0.4

### Bug Fixes

- Fix blink issue

### Enhancements

- Add support of Drag Handler for `TargetPlatformVariant.desktop`





