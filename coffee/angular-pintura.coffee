module = angular.module('ngPintura', [])


class NGPImageLoader
  constructor: (@files = [], @loadedCb, @progressCb) ->
    @loaded = 0
    for file in @files
      file.image = new Image()
      file.image.onload = @onload
      file.image.src = file.url

  onload: =>
    @loaded += 1
    @progressCb(@loaded / @files.length) if @progressCb
    @loadedCb(@files) if @loaded >= @files.length


class NGPCanvas
  constructor: ->
    # create konva stage and items
    # Stage
    # -> Layer 
    #   -> IndicatorRect
    # -> ImageLayer
    #   -> HotspotsGroup
    #   -> Image
    stageNode = new Konva.Stage
      container: angular.element('<div>')[0]
    layerNode = new Konva.Layer()
    indicatorNode = new Konva.Rect()
    imageLayerNode = new Konva.Layer()
    hotspotsNode = new Konva.Group()
    imageNode = new Konva.Image()
    stageNode.add(layerNode)
    layerNode.add(indicatorNode)
    stageNode.add(imageLayerNode)
    imageLayerNode.add(imageNode)
    imageLayerNode.add(hotspotsNode)

    @progressCb = undefined
    @stage = stageNode
    @layer = layerNode
    @indicator = new NGPIndicator(indicatorNode)
    @imageLayer = new NGPImage(imageLayerNode)
    @hotspots = hotspotsNode
    @image = imageNode

  resize: (width, height) ->
    @stage.size
      width: width
      height: height
    # keep indicator in center
    @indicator.node.position
      x: width / 2
      y: height / 2
    @imageLayer.adjustScaleBounds(@stage.size())

  # loads new image and shows loading indicator 
  imageChange: (src, showIndicator) ->
    @image.node.visible(false)
    if angular.isUndefined(showIndicator) || showIndicator
      @indicator.node.visible(true)
      @indicator.animation.start()
    if typeof src is 'string' 
      Konva.Image.fromURL(src, (newImage) =>
        @setImage(newImage.image())
        newImage.destroy()
      ) # fromUrl
    else if src instanceof Image
      @setImage(src)
    else if src instanceof Array
      @setCollage(src) 
    else if (window.console)
      console.log 'src is empty or unknown format:', src

  # replaces image by new image and hides indicator
  setImage: (newImage) ->
    @image.node.size
      width: newImage.width
      height: newImage.height
    @image.node.image(newImage)
    @indicator.node.visible(false)
    @indicator.animation.stop()
    @image.adjustScaleBounds(@stage.size())
    @image.node.visible(true)
    @image.node.parent.draw()
    @image.node.fire(@image.LOADED)

  # 
  setCollage: (files) ->
    loaded = (images) =>
      rowsX = 0
      rowsY = 0
      tmpLayer = new Konva.Layer()
      for image in images
        rowsX = Math.max(image.x+1, rowsX)
        rowsY = Math.max(image.y+1, rowsY)
        tmpLayer.add new Konva.Image
          image: image.image
          x: image.x*image.image.width
          y: image.y*image.image.height
      # create collage as one image
      tmpLayer.toImage
        x: 0
        y: 0
        width: rowsX*images[0].image.width
        height: rowsY*images[0].image.height
        callback: (image) => 
          @setImage(image)
          tmpLayer.destroy()
    # init loading
    new NGPImageLoader(files, loaded, @progressCb)

###
#
###
class NGPIndicator
  constructor: (@node) ->
    @rotationSpeed = 270
    @node.setAttrs
      width: 50
      height: 50
      fill: 'pink'
      stroke: 'white'
      strokeWidth: 4
      zIndex: 99
      visible: false
      offset: {x:25, y:25}
    # define indicator animation
    _animFn = (frame) =>
      angleDiff = frame.timeDiff * @rotationSpeed / 1000
      @node.rotate(angleDiff)
    @animation = new Konva.Animation(_animFn, @node.parent)

###
#
###
class NGPImage
  constructor: (@node) ->
    @LOADED = 'loaded'
    @node.draggable(true)
    @minScale = 0.5
    @maxScale = 1
    @tween = undefined # Konova.Tween
    @tweenDuration = 0.25

  adjustScaleBounds: (viewport) ->
    return if not @node.width() or not @node.height()
    # adjust scale bounds
    @minScale = viewport.width / @node.width()
    # if image doesnt fit vertically with new minScale
    if viewport.height < @node.height()*@minScale
      # compute min scale based on heights of stage and image
      @minScale = viewport.height / @node.height()
    # never exceed/scale up original image size
    @minScale = Math.min(@minScale, 1)

  _fitScale: (scale) ->
    Math.min(Math.max(scale, @minScale), @maxScale)
  
  # scales picture to minScale and rotates it by degrees
  rotateByVectorTween: (degrees, callback) ->
    imgScaled =
      width: @node.width() * @minScale
      height: @node.height() * @minScale
    attrs =
      offsetY: 0
      offsetX: 0
      scaleX: @minScale
      scaleY: @minScale
      x: if imgScaled.width < @node.getStage().width() then (@node.getStage().width() - (imgScaled.width)) / 2 else 0
      y: if imgScaled.height < @node.getStage().height() then (@node.getStage().height() - (imgScaled.height)) / 2 else 0
    newPos = @node.rotation() + degrees
    orientationSin = Math.round(Math.sin(newPos * Math.PI / 180))
    orientationCos = Math.round(Math.cos(newPos * Math.PI / 180))
    if orientationCos == 1 # ↑
      attrs.offsetX = 0
      attrs.offsetY = 0
    else if orientationCos == -1 # ↓
      attrs.offsetX = @node.width()
      attrs.offsetY = @node.height()
    else if orientationSin == 1 # →
      attrs.offsetX = @node.width() / 2 - (@node.height() / 2)
      attrs.offsetY = @node.width() / 2 + @node.height() / 2
    else if orientationSin == -1 # ←
      attrs.offsetX = @node.width() / 2 + @node.height() / 2
      attrs.offsetY = -(@node.width() / 2 - (@node.height() / 2))
    if newPos != @node.rotation()
      if @tween
        @tween.pause().destroy()
      # create tween
      @tween = new (Konva.Tween)(angular.extend(attrs,
        node: @node
        rotation: newPos
        duration: 0.1
        easing: Konva.Easings.EaseOut
        onFinish: callback))
      # play
      return @tween.play()
    return

  _zoomToPointAttrs: (scale, point) ->
    scaling = @node.scaleX() + scale
    # keep scale within bounds
    scaling = @_fitScale(scaling)
    # translate point to local coordinates
    imgPoint = @node.getAbsoluteTransform().copy().invert().point(point)
    # set new position: current position minus distance between current scaled point and point with new scale
    attrs =
      scaleX: scaling
      scaleY: scaling
    newPos = @node.rotation()
    orientationSin = Math.round(Math.sin(newPos * Math.PI / 180))
    orientationCos = Math.round(Math.cos(newPos * Math.PI / 180))
    if orientationCos == 1 # ↑
      attrs.x = point.x - (imgPoint.x * scaling)
      attrs.y = point.y - (imgPoint.y * scaling)
    else if orientationCos == -1 # ↓
      attrs.x = point.x - ((@node.width() - (imgPoint.x)) * scaling)
      attrs.y = point.y - ((@node.height() - (imgPoint.y)) * scaling)
    else if orientationSin == 1 # →
      attrs.x = point.x - ((@node.height() - (imgPoint.y)) * scaling) - (@node.offsetX() * scaling)
      attrs.y = point.y - (imgPoint.x * scaling) + @node.offsetX() * scaling
    else if orientationSin == -1 # ←
      attrs.x = point.x - (imgPoint.y * scaling) + @node.offsetY() * scaling
      attrs.y = point.y - ((@node.width() - (imgPoint.x)) * scaling) - (@node.offsetY() * scaling)
    attrs

  # performs zoom to any point
  zoomToPoint: (scale, point) ->
    @node.setAttrs(@_zoomToPointAttrs(scale, point))
    @node.parent.draw()

  # performs zoom to current pointer position
  zoomToPointer: (scale) ->
    @zoomToPoint(scale, @node.getStage().getPointerPosition())

  _stageCenter: ->
    center = 
      x: @node.getStage().width() / 2
      y: @node.getStage().height() / 2

  # performs zoom to center of stage
  zoomToCenter: (scale) ->
    @zoomToPoint(scale, @_stageCenter())

  # perform zoom to point as animation (tween)
  zoomToPointTween: (scale, point, callback) ->
    tweenAttrs = @_zoomToPointAttrs(scale, point)
    # do not redeclare tween if current state already equals    
    if scale isnt @node.scaleX() or tweenAttrs.x isnt @node.x() or tweenAttrs.y isnt @node.y()
      # freeze state and destroy prior animation
      # !!! do not use finish() here, it'll cause adoptation of prior tween state !!
      # at least onFinish will be fired because after pause and destroy the tween is getting started again
      @tween.pause().destroy() if @tween
      # create tween 
      @tween = new Konva.Tween angular.extend(tweenAttrs,
        node: @node
        duration: @tweenDuration
        easing: Konva.Easings.EaseOut
        onFinish: callback 
      ) 
      # play
      @tween.play()

  # performs coom to center of stage 
  zoomToCenterTween: (scale, callback) ->
    @zoomToPointTween(scale, @_stageCenter(), callback)

  # perform move to point as animation
  moveByVectorTween: (v, callback) ->
    pos = @node.position()
    pos.x += v.x if v.x
    pos.y += v.y if v.y    
    # do not redeclare tween if current state already equals    
    if pos.x isnt @node.x() or pos.y isnt @node.y()
      # freeze state and destroy prior animation
      # !!! do not use finish() here, it'll cause adoptation of prior tween state !!
      # at least onFinish will be fired because after pause and destroy the tween is getting started again
      @tween.pause().destroy() if @tween
      # create tween 
      @tween = new Konva.Tween angular.extend(pos,
        node: @node
        duration: @tweenDuration
        easing: Konva.Easings.EaseOut
        onFinish: callback 
      ) 
      # play
      @tween.play()

  fitInViewTween: (callback) ->
    imgScaled =
      width: @node.width()*@minScale
      height: @node.height()*@minScale
    attrs =
      scaleX: @minScale
      scaleY: @minScale
      x: if imgScaled.width < @node.getStage().width() then (@node.getStage().width()-imgScaled.width) / 2 else 0
      y: if imgScaled.height < @node.getStage().height() then (@node.getStage().height()-imgScaled.height) / 2 else 0
    # do not redeclare tween if current state already equals    
    if attrs.x isnt @node.x() or attrs.y isnt @node.y() or attrs.scaleX isnt @node.scaleX()
      # freeze state and destroy prior animation
      # !!! do not use finish() here, it'll cause adoptation of prior tween state !!
      # at least onFinish will be fired because after pause and destroy the tween is getting started again
      @tween.pause().destroy() if @tween
      # create tween 
      @tween = new Konva.Tween angular.extend(attrs,
        node: @node
        duration: @tweenDuration
        easing: Konva.Easings.EaseOut
        onFinish: callback 
      ) 
      # play
      @tween.play()

###*
# pintura container
# creates and shares paperjs scope with child directives
# creates canvas
###
module.directive 'ngPintura', ($window) ->
  directive = 
    transclude: true
    scope:
      src: '=ngpSrc'
      scaling: '=?ngpScaling'
      position: '=?ngpPosition'
      fitOnload: '=?ngpFitOnload'
      maxScaling: '=?ngpMaxScaling'
      scaleStep: '=?ngpScaleStep'
      mwScaleStep: '=?ngpMwScaleStep'
      showIndicator: '=?ngpShowIndicator'
      moveStep: '=?ngpMoveStep'
      progress: '=?ngpProgress'
      hotspots: '=?ngpHotspots'
    link: (scope, element, attrs, ctrl, transcludeFn) ->
      # initializing Canvas
      ngPintura = new NGPCanvas()

      # slider value and conversion functions
      scope.slider =
        # current slider value
        value: undefined
        # sets slider value by passing scale
        fromScaling: (scale) -> @value = parseInt(((scale-ngPintura.image.minScale) / (ngPintura.image.maxScale-ngPintura.image.minScale))*100)
        # returns corresponding scale value to current slider value
        toScaling: -> (ngPintura.image.maxScale-ngPintura.image.minScale) * (@value / 100) + ngPintura.image.minScale 

      resizeContainer = ->
        ngPintura.resize(element[0].clientWidth, element[0].clientHeight)
        setScalingDisabled()

      # changes image
      imageChange = ->
        ngPintura.imageChange(scope.src, scope.showIndicator)

      positionChange = -> 
        if scope.position?.x and scope.position?.y
          ngPintura.image.node.position(scope.position)
          ngPintura.layer.draw()

      scalingChange = ->
        ngPintura.image.node.scale
          x: scope.scaling
          y: scope.scaling
        ngPintura.layer.draw()
        scope.slider.fromScaling(scope.scaling)

      # performs zoom to point based on mousewheel event
      mouseWheel = (e) ->
        e.evt.preventDefault()
        # perform zoom to point
        if e.evt.wheelDeltaY > 0
          ngPintura.image.zoomToPointer(scope.mwScaleStep)
        else
          ngPintura.image.zoomToPointer(-scope.mwScaleStep)
        # keeps angular scope synchronized
        applySyncScope()

      # keeps scope synchronized with stage kontext
      syncScope = ->
        scope.position = ngPintura.image.node.position()
        scope.scaling = ngPintura.image.node.scaleX()
        if scope.slider.toScaling() isnt scope.scaling
          scope.slider.fromScaling(scope.scaling)

      # synchronize scope within agnular context
      applySyncScope = ->
        scope.$apply(syncScope)

      # runs animation scales and moves image so it fits in view
      scope.fitInView = ->
        ngPintura.image.fitInViewTween(applySyncScope)

      # user clicks move up
      scope.moveUp = -> 
        ngPintura.image.moveByVectorTween({y: scope.moveStep}, applySyncScope)

      # user clicks move down
      scope.moveDown= ->
        ngPintura.image.moveByVectorTween({y: -scope.moveStep}, applySyncScope)

      # user clicks move right
      scope.moveRight = ->
        ngPintura.image.moveByVectorTween({x: -scope.moveStep}, applySyncScope)

      # user clicks move left
      scope.moveLeft = ->
        ngPintura.image.moveByVectorTween({x: scope.moveStep}, applySyncScope)

      # user clicks zoom in
      scope.zoomIn = ->
        ngPintura.image.zoomToCenterTween(scope.scaleStep, applySyncScope)

      # user clicks zoom out
      scope.zoomOut = ->
        ngPintura.image.zoomToCenterTween(-scope.scaleStep, applySyncScope)

      # user clicks rotate left
      scope.rotateLeft = ->
        ngPintura.image.rotateByVectorTween(-90, applySyncScope);

      # user clicks rotate right
      scope.rotateRight = ->
        ngPintura.image.rotateByVectorTween(90, applySyncScope);

      # zooms to sliders new corrisponding scaling
      scope.sliderChange = ->
        scale = scope.slider.toScaling() - ngPintura.image.node.scaleX()
        ngPintura.image.zoomToCenter(scale)
        syncScope()

      setScalingDisabled = ->
        scope.scalingDisabled = ngPintura.image.minScale >= ngPintura.image.maxScale

      imageLoad = ->
        scope.fitInView() if scope.fitOnload
        setScalingDisabled()
        
      # configure scaling bounds
      maxScalingChange = ->
        ngPintura.image.maxScale = scope.maxScaling
        setScalingDisabled()

      hotspotsChange = ->
        # remove all hotspots
        ngPintura.hotspots.removeChildren()
        if scope.hotspots
          ngPintura.hotspots.add.apply(ngPintura.hotspots, scope.hotspots)

      ngPintura.progressCb = (progress) ->
        scope.$apply -> 
          scope.progress = progress

      # defaults
      scope.maxScaling ?= 1
      scope.scaleStep ?= 0.4
      scope.mwScaleStep ?= 0.1
      scope.moveStep ?= 100
      scope.fitOnload ?= true
      # append stage container to current element
      element.append(ngPintura.stage.content)
      # resize stage container
      resizeContainer()
      # register listeners
      angular.element($window).on('resize', resizeContainer)
      scope.$watch('src', imageChange)
      scope.$watch('position', positionChange, true)
      scope.$watch('scaling', scalingChange)
      scope.$watch('maxScaling', maxScalingChange)
      scope.$watch('hotspots', hotspotsChange)
      ngPintura.image.node.on('dragend', applySyncScope)
      ngPintura.image.node.on('mousewheel', mouseWheel)
      ngPintura.image.node.on(ngPintura.image.LOADED, imageLoad)
      # append transcluded template and pass scope to it
      transcludeFn( scope, (clonedTranscludedTemplate) -> element.append(clonedTranscludedTemplate) )