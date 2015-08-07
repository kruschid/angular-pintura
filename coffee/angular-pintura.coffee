module = angular.module('ngPintura', [])

# access to global paper object
module.value('ngpKonva', window.Konva)

###*
# pintura container
# creates and shares paperjs scope with child directives
# creates canvas
###
module.directive 'ngPintura', (ngpKonva, $window) ->
  directive = 
    transclude: true
    scope:
      src: '='
      scale: '='
      position: '='
      fitOnload: '='
    link: (scope, element, attrs, ctrl, transcludeFn) ->
      # konva stage
      stage = undefined
      # konva layer
      layer = undefined
      # image object
      image = 
        # konva image
        shape: undefined
        # konva tween (to fit image within bound)
        tween: undefined
        tweenAttrs: {}
        # scale boundaries
        borderWhitespace: 50
        minScale: 0.2
        maxScale: 5
        scaleStep: 0.5
        fitScale: (scale) -> Math.min(Math.max(scale, @minScale), @maxScale)
      # indicator object
      indicator = 
        # konva rect
        shape: undefined
        # konva animation
        animation: undefined
      # slider value an conversion functions
      scope.slider =
        # current slider value
        value: undefined
        # sets slider value by passing scale
        fromScale: (scale) -> @value = parseInt(((scale-image.minScale)/(image.maxScale-image.minScale))*100)
        # returns corresponding scale value to current slider value
        toScale: -> (image.maxScale-image.minScale) * (@value/100) + image.minScale 

      # creates stage and items
      initStage = ->
        # create container
        container = angular.element('<div>')
        element.append(container)
        # create konva stage and items
        stage = new ngpKonva.Stage
          container: container[0]
          width: element[0].clientWidth
          height: element[0].clientHeight
        layer = new ngpKonva.Layer()
        image.shape = new ngpKonva.Image
          draggable: true
        scope.scale ?= image.shape.scaleX()
        scope.position ?= image.shape.position()
        indicator.shape = new ngpKonva.Rect()
        # create hierarchy
        stage.add(layer)
        layer.add(image.shape)
        layer.add(indicator.shape)

      # set indicator attributes and creates indicator animation
      initIndicator = ->
        indicator.shape.setAttrs
          x: stage.width()/2
          y: stage.height()/2
          width: 50
          height: 50
          fill: 'pink'
          stroke: 'white'
          strokeWidth: 4
          zIndex: 99
          visible: false
          offset:
              x: 25
              y: 25
        # define indicator animation
        animFn = (frame)->
          speed = 270 # degrees per second
          angleDiff = frame.timeDiff * speed / 1000
          indicator.shape.rotate(angleDiff)
        # register animation
        indicator.animation = new ngpKonva.Animation(animFn, layer)

      # Adjusts scale bounds to new image size
      # Computes minimum scale so the whole image fits into stage 
      adjustScaleBounds = ->
        # make sure image fits horizontally
        image.minScale = stage.width()/(image.shape.width()+2*image.borderWhitespace)
        # if image doesnt fit vertically with new minScale
        if stage.height() < (image.shape.height()+2*image.borderWhitespace)*image.minScale
          # compute min scale based on heights of stage and image
          image.minScale = stage.height()/(image.shape.height()+2*image.borderWhitespace)
        # half of 
        #minScale /= 1.5

      # changes size of stage according to new element size
      resizeStage = ->
        stage.size
          width: element[0].clientWidth
          height: element[0].clientHeight
        indicator.shape.position
          x: stage.width()/2
          y: stage.height()/2
        adjustScaleBounds()

      # loads new image and shows loading indicator 
      imageChange = ->
        ngpKonva.Image.fromURL(scope.src, imageLoad)
        indicator.shape.visible(true)
        indicator.animation.start()

      # inserts new image and hides loading indicator
      imageLoad = (newImage) ->
        image.shape.size(newImage.size())
        image.shape.image(newImage.image())
        newImage.destroy()
        indicator.shape.visible(false)
        indicator.animation.stop()
        adjustScaleBounds()
        adjust()

      # performs zoom to point based on mousewheel event
      mouseWheel = (e) ->
        e.evt.preventDefault() 
        if e.evt.wheelDeltaY > 0
          scope.scale += 0.1
        else
          scope.scale -= 0.1
        # perform zoom to point
        zoomToPoint(stage.getPointerPosition())
        # # keeps angular scope synchronized
        # scope.$apply()

      # performs zoom zo point
      zoomToPoint = (absPoint) ->
        # keep scale within bounds 
        scope.scale = image.fitScale(scope.scale)
        # translate point to local coordinates
        point = image.shape.getAbsoluteTransform().copy().invert().point(absPoint)
        # set new position: current position minus distance between current scaled point and point with new scale
        scope.position =         
          x: -point.x + absPoint.x/scope.scale
          y: -point.y + absPoint.y/scope.scale
        # perform animation
        adjust()

      # performs zoom to center of stage
      zoomToCenter = ->
        # compute center point
        point =
          x: stage.width()/2
          y: stage.height()/2
        # perform the zoom
        zoomToPoint(point)

      # applies new position 
      dragEnd = ->
        scope.$apply ->
          scope.position = 
            x: image.shape.x()/image.shape.scaleX()
            y: image.shape.y()/image.shape.scaleY()

      # keeps image in viewport
      keepInView = ->
        # define viewport bounds
        bounds =
          x1: -image.shape.width() + (stage.width()-image.borderWhitespace)/scope.scale
          y1: -image.shape.height() + (stage.height()-image.borderWhitespace)/scope.scale
          x2: image.borderWhitespace/scope.scale
          y2: image.borderWhitespace/scope.scale
        # keep position  within view bounds
        scope.position =
          x: Math.min(Math.max(scope.position.x, bounds.x1), bounds.x2)
          y: Math.min(Math.max(scope.position.y, bounds.y1), bounds.y2)
        # center image horizontally if image smaller than viewport
        if stage.width()/scope.scale >= image.shape.width()+image.borderWhitespace*2
          # center group/image vertically move half of distance between image width and stage width
          scope.position.x = (stage.width()/scope.scale - image.shape.width())/2
        # center image vertically if image smaller than viewport
        if stage.height()/scope.scale >= image.shape.height()+image.borderWhitespace*2
          # center group/image vertically move half of distance between image height and stage height
          scope.position.y = (stage.height()/scope.scale - image.shape.height())/2

      # perform animation to new scale and position
      adjust = ->
        # do not run this method if if pos or scale is not a number
        return if not scope.position or isNaN(scope.position.x) or isNaN(scope.position.y) or isNaN(scope.scale)
        # keep scale and postion within bounds 
        scope.scale = image.fitScale(scope.scale)
        keepInView()
        # if new pos is different from current pos
        if scope.scale isnt image.shape.scaleX() or scope.position.x*scope.scale isnt image.shape.x() or scope.position.y*scope.scale isnt image.shape.y()
          # freeze state and destroy prior animation
          # !!! do not use finish() here, it'll cause adoptation of prior tween state !!
          # at least onFinish will be fired because after pause and destroy the tween is getting started again
          image.tween.pause().destroy() if image.tween
          # create tween 
          image.tween = new ngpKonva.Tween  
            x: scope.position.x * scope.scale # multiplication is obligatory because in the new state the image is bigger/smaller
            y: scope.position.y * scope.scale
            scaleX: scope.scale
            scaleY: scope.scale
            node: image.shape
            duration: 0.25
            easing: ngpKonva.Easings.EaseOut
            onFinish: ->
              # teile angular mit, dass scope modifiziert wurde
              scope.$apply()
          # play
          image.tween.play()

      # sets slider value from correpsonding scale
      scaleChange = ->
        scope.slider.fromScale(scope.scale)
        adjust()

      # keeps image within bounds
      scope.fitInView = ->
        # set scale to min scale
        scope.scale = image.minScale

      # zooms to sliders new corrisponding scaling
      scope.sliderChange = ->
        scope.scale = scope.slider.toScale()
        zoomToCenter()

      # user clicks move up
      scope.moveUp = ->
        scope.position.y += 100

      # user clicks move down
      scope.moveDown= ->
        scope.position.y -= 100

      # user clicks move right
      scope.moveRight = ->
        scope.position.x -= 100

      # user clicks move left
      scope.moveLeft = ->
        scope.position.x += 100

      # user clicks zoom in
      scope.zoomIn = ->
        scope.scale += image.scaleStep
        zoomToCenter()

      # user clicks zoom out
      scope.zoomOut = ->
        scope.scale -= image.scaleStep
        zoomToCenter()

      # contructor
      initStage()
      initIndicator()
      scope.$watch('src', imageChange)
      scope.$watch('position', adjust, true)
      scope.$watch('scale', scaleChange)
      angular.element($window).on('resize', resizeStage)
      image.shape.on('dragend', dragEnd)
      image.shape.on('mousewheel', mouseWheel)
      # pass scope into transcluded template
      transcludeFn( scope, (clonedTranscludedTemplate) -> element.append(clonedTranscludedTemplate) )