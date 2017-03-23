# EventTimeLine directive
#### Shows the time line of a calendar event

## Usage

First, include `commonDirectives` as a dependency of the current controller:
```javascript
var app = angular.module('my-controller', [..., 'commonDirectives']);
```

Then in your view use it as `tooltip` directive:
```html
<event-time-line event-id="1234"></event-time-line>
```

### Examples
```html
<event-time-line event-id="1234"></event-time-line>
  
<event-time-line event-id="{{ eventId }}"></event-time-line>
```
