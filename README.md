# Angular Pintura

*angular-pintura* is a image viewer based on [AngularJS 1.4](https://angularjs.org/) and [Konva 0.9.5](http://konvajs.github.io/). Check out the [demo-page](http://kruschid.github.io/angular-pintura/).
## Installation

Open your terminal, change to project directory and run 

    bower install angular-pintura --save

Or add `"angular-pintura":"latest"` to your list of dependencies in `bower.json` and run `bower install` aufterwards.

  
## How to Use

Following examples are written in [Jade](http://jade-lang.com/), [SASS](http://sass-lang.com/) and [CoffeScript](http://coffeescript.org/). Keep in mind that those examples won't work in a pure HTML/JS/CSS-Project without preceding compilation. 

### Include Dependencies

Since *angular-pintura* is based on [AngularJS](https://angularjs.org/) and [Konva](http://konvajs.github.io/) you have to include those libraries before you include *angular-pintura*.

    script(src='bower_components/angular/angular.js')
    script(src='bower_components/konva/konva.js')
    script(src='bower_components/angular-pintura/angular-pintura.js')
    script(src='src/app.js') # your app

Assuming your angular-app is in `src/app.js`, you have to add `'ngPintura'` module to your app dependencies between the squared brackets:

    app = angular.module('app', ['ngPintura'])

Within your controller you might want to pass some initial params.
    
    $scope.image =
    src: 'images/img1.jpg'
    position: 
      x: -137.5
      y: -68
    scaling: 2

Now just use the `ng-pintura` directive in your Jade-File:

    ng-pintura(
      ngp-src='image.src', 
      ngp-scaling='image.scaling',
      ngp-position='image.position'
    )

Or in your HTML-File:
    
    <ng-pintura ngp-src='image.src', 
                ngp-scaling='image.scaling',
                ngp-position='image.position'></ng-pintura>

### Custom Control Elements

You might wonder how to add the control elements (buttons, slider) you saw on the [demo page](http://kruschid.github.io/angular-pintura/). Since the `ng-pintura` directive uses transclusion you can easily add your own template to define and style your own control elements. 

The following Jade template mainly uses predefined classes from [Bootstrap 3](http://getbootstrap.com/):

    ng-pintura(ngp-src='image.src')
      #zoomslider
        input(ng-model='slider.value', ng-change='sliderChange()', orient='vertical', type='range', min='0', max='100', step='1', ng-disabled='scalingDisabled')
      button.btn.btn-default#zoomin(ng-click='zoomIn()', ng-disabled='scalingDisabled'): span.glyphicon.glyphicon-plus
      button.btn.btn-default#zoomout(ng-click='zoomOut()', ng-disabled='scalingDisabled'): span.glyphicon.glyphicon-minus
      button.btn.btn-default#moveup(ng-click='moveUp()'): span.glyphicon.glyphicon-chevron-up
      button.btn.btn-default#movedown(ng-click='moveDown()'): span.glyphicon.glyphicon-chevron-down
      button.btn.btn-default#moveleft(ng-click='moveLeft()'): span.glyphicon.glyphicon-chevron-left
      button.btn.btn-default#moveright(ng-click='moveRight()'): span.glyphicon.glyphicon-chevron-right
      button.btn.btn-default#movecenter(ng-click='fitInView()'): span.glyphicon.glyphicon-screenshot

You can include the style definitions from the file `sass/_panoramacontrols.sass` to your sass file if you like to have the same controls in your project:

    @import bower_components/angular-pintura/sass/_panoramacontrols

### Directive Attributes

As you can see in the example above and on the [demo page](http://kruschid.github.io/angular-pintura/), angular-pintura directive provides some attributes. With these attributes you are able to manipulate the view from your controller.

#### ngp-src (string/Image-Object)
Image-Source. URL-String, `Image`-Object or `Array` of coords and urls. See [demo page](http://kruschid.github.io/angular-pintura/).

In case of source is an array each element should contain folowing properties:

    x: <Number>
    y: <Number>
    url: <String>

#### ngp-position ({x:number, y:number})
Sets the current position of image. See example above.

#### ngp-move-step (number)
**default:100 (pixel)**

The value added to/subtract from position on moveUp/moveDown/moveRight/moveLeft.

#### ngp-scaling (number)
Current scaling of image.

#### ngp-max-scaling (number)
**default: 1 (100%)**

Maximum value for scaling.  

#### ngp-scale-step (number)
**default: 0.2**

The value added to/subtract from scaling on zoomIn/zoomOut.

#### ngp-mw-scale-step (number)
**default: 0.1**

The value added to/subtract from scaling on zoomIn/zoomOut caused by mouse wheel.

#### ngp-fit-onload (boolean)
**default: true**

Defines wether the directive should fit the image to view boundswhen a image is ready to display. Not recommend when you want to navigate through a set of similar photos (surveillance pictures) and you are intresseted in a certain image detail. 

#### ngp-progress (ref)
**range: 0 to 1**

Represents loading progress of collage images. Pass a variable reference to it (e.g. `ngp-progress='image.progress'`) and angular-pintura will continously assign the progress state to the variable behind that reference. You will need this feature for implementing your loading bar.

#### ngp-show-indicator
**default: true**

Turn on/off the loading indicator. You could use this option to implement your custom indicator instead.

*Thanks to @VictorCavalcante*

### Directive Scope

Because pintura supports transclusion you are able to use your own template to add custom controls to your image viewer. Those controls can manipulate the view through a set of functions provided in the directive scope:

#### zoomIn()
Performs zoom-in animation to center of view.

#### zoomOut()
Performs zoom-out animation from center of view.

#### moveUp()
Moves image upwards by `move-step`.

#### moveDown()
Moves image downwards by `move-step`.

#### moveLeft()
Moves image leftwards by `move-step`.

*Thanks to @VictorCavalcante*

#### moveRight()
Moves image rightwards by `move-step`.

*Thanks to @VictorCavalcante*

#### rotateLeft()
Rotates image by 90 degrees.

#### rotateRight()
Rotates image by 90 degrees.

#### fitInView()
Adjusts image `scaling` and `position` so that it fits in view. In cases of small images this function scales images to its original size and displays it at the centers of view (makes sure that scaling never exceeds 100%).

#### scalingDisabled (boolean)
Use `scalingDisabled` to hide/disable your control elements when scaling is not possible. Since *angular-pintura* was made to zoom and pan images it has a `minScale` and `maxScale` properties. While the second can be set by the corresponding attribute (`min-scale`, see above) the first is beeing set automatically everytime the view-container is being resized or a new image loaded. In state of current scaling is equal to `minScale` the image fits the view bounds. But in case of a small image, an image smaller than view bounds, the image is beeing centered within the view because its ugly and usually makes no sense to scale up small images. In this case `minScale` has the value of `1`, the original image size. Additionally if the `maxScale` has been set to the same value it is not possible to change the image scaling and also no need to show scaling controls.