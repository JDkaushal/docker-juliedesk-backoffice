# Dropdown directive
#### Shows a dropdown

## Usage

First, include `commonDirectives` as a dependency of the current controller:
```javascript
var app = angular.module('my-controller', [..., 'commonDirectives']);
```

Then in your view use it as `tooltip` directive:
```html
<div class="my-cool-input"
     dropdown
     dropdown-data="{europe_paris: {label: 'Paris'}, america_new_york: {label: 'New-York'}}"
     dropdown-select-item="selectCity(value)">Choose a city</div>
```

### Options

* `dropdown`: *Required* Initialize the dropdown
* `dropdown-data`: Pass the data of the dropdown. Should be a hash of format: {value_a: {label: "Label A"}, ...}
* `dropdown-select-item`: Pass a function using `value` parameter which will be called on item selection

### Other

* Trigger the dropdown with a button:*If the element on which you apply the directive contains an element of class `dropdown-button`, the dropdown will appear when you click on the child and not on the parent.* 

### Examples
```html
<div class="my-cool-input"
     dropdown
     dropdown-data="{europe_paris: {label: 'Paris'}, america_new_york: {label: 'New-York'}}"
     dropdown-select-item="selectCity(value)">Choose a city</div>
  
<div class="my-cool-input"
     dropdown
     dropdown-data="{europe_paris: {label: 'Paris'}, america_new_york: {label: 'New-York'}}"
     dropdown-select-item="selectCity(value)">Choose a city
     <div class="dropdown-button">Click me to trigger dropdown</div>
 </div>
```

