# ConstraintTile directive
#### Shows a constraint tile

##### NB: Read-only mode only supported for now. 

## Usage

First, include `commonDirectives` as a dependency of the current controller:
```javascript
var app = angular.module('my-controller', [..., 'commonDirectives']);
```

Then in your view use it as `tooltip` directive:
```js
$scope.myCoolConstraintHash = {
    data: {
        attendee_email: "bla@bla.com",
        constraint_nature: "can",
        constraint_when_nature: "custom",
        dates: ["2017-05-25", "2017-05-27"],
        start_time: "",
        end_time: "",
        timezone: "Europe/Paris"
    },
    readOnly: true
} 
```


```html
<div constraint-tie
     constraint-tile-data="myCoolConstraintHash">
     </div>
```

### Options

* `constraint-tile`: *Required* Initialize the dropdown
* `constraint-tile-data`: *Required* Pass the data of the dropdown. Should be a string referecing a property of a current scope, containing a constraint hash.