# Common directives

## Usage

To use the common directives, include `commonDirectives` as a dependency of the current controller:
```javascript
var app = angular.module('my-controller', [..., 'commonDirectives']);
```


## Available directives
* [Tooltip](tooltip.md)
* [Dropdown](dropdown.md)
* [EventTimeLine](event_time_line.md)
* [ConstraintTile](constraint_tile.md)

## Development

To add another common directive:
* Place the JS file in /app/assets/javascripts/angular/common_directives/
* Require it in /app/assets/javascripts/angular_common_directives.js
* Place the CSS file in /app/assets/stylesheets/common_directives/
* Import it in /app/assets/stylesheets/angular_common_directives.css.scss
