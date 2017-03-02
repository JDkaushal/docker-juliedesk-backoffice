# Tooltip directive
#### Shows a custom tooltip on hover.

## Usage

First, include `commonDirectives` as a dependency of the current controller:
```javascript
var app = angular.module('my-controller', [..., 'commonDirectives']);
```

Then in your view use it as `tooltip` directive:
```html
<div class="my-cool-button"
     tooltip="You should click me...">Click me!</div>
```

### Options

* `tooltip`: *Required* Define the tooltip message
* `tooltip-right`: Define the directive to make tooltip origin at the right of the element
* `tooltip-top`: Define the directive to make tooltip appear on top of the element
* `tooltip-delay`: Define the directive to make tooltip appear after the delay (ms)

### Examples
```html
<div class="my-cool-button"
     tooltip="You should click me...">Click me!</div>
  
<div class="my-cool-button"
     tooltip="You will see me after 0.5s..."
     tooltip-delay="500">Click me!</div>
  
<div class="my-cool-button"
     tooltip="I appear on top-right of the element"
     tooltip-right
     tooltip-top>Click me!</div>
```
