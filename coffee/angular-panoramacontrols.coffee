###*
# Ermöglicht Scale-to-Point mit Mausrad innerhalb des Panoramas.
# Ermöglicht Drag-to-pan mit Maus- oder Touchbedienung.
# Ermöglicht Fernsteuerung (Position&Scale) des Panoramaviewer anhand von Events, die von der Stage gebroadcastet werden
# Informiert bei Änderung an Position&Scale in Form von Events, die von der Stage gebroadcastet werden
# Sorgt dafür, dass die Move-/Scale-Operationen das Bild nicht auserhälb der Zeichenfläche schieben.
# führt Event-Binding durch (Control-Buttons zu Plugin)
###
panoramaControlsDirective = ->
  # post link function
  linkFunc = (scope, el, attrs, viewer) ->
    ###*
    # Adds whitespace to layer-dragbounds computet in {{#crossLink "_adjustLayer:method"}}{{/crossLink}}
    # @private
    # @property _boundsWhitespace
    # @type Number
    ###
    _boundsWhitespace = 100

    ###*
    # minimal scale value
    # @private
    # @property _minScale
    # @type Number
    ###
    _minScale = if not scope.minScale then 0.5 else parseFloat(scope.minScale)

    ###*
    # maximal scale value
    # @private
    # @property _maxScale
    # @type Number
    ###
    _maxScale = if not scope.maxScale then 5 else parseFloat(scope.maxScale)

    ###*
    # transform animation 
    # @private
    # @property _adjustTween
    # @type Kinetic.Tween
    ###   
    _adjustTween = undefined

    ###*
    # scale step
    # @private
    # @property _changeScaleStep
    # @type Kinetic.Tween
    ###   
    _changeScaleStep = if not scope.changeScaleStep then 0.5 else parseFloat(scope.changeScaleStep)
    
    ###*
    # initiaö slider value
    # @property scope.sliderValue
    # @type Kinetic.Tween
    ###   
    scope.sliderValue = 0
    
    ###*
    # Runs function that keeps image within bounding box defined by stage size
    # @private
    # @method _stageDragend
    ###
    _stageDragend = ->
      layer = viewer().layer
      scope.$apply ->
        scope.position = 
          x: layer.x()/layer.scaleX()
          y: layer.y()/layer.scaleY()

    ###*
    # On resize stage 
    # @private
    ###
    _resizeStage = ->
      scope.$apply ->
        _adjustScaleBounds()
        scope.sliderValue = _scaleToSliderValue(scope.scale)

    ###*
    # Adjusts scale bounds to new image size
    # Computes minimum scale so the whole image fits into stage 
    # @private
    # @method _adjustScaleBounds
    ###
    _adjustScaleBounds = ->
      [stage, image] = [viewer(), viewer().image]
      # make sure image fits horizontally
      _minScale = stage.width()/image.width()
      # if image doesnt fit vertically with new minScale
      if stage.height() < image.height()*_minScale
        # compute min scale based on heights of stage and image
        _minScale = stage.height()/image.height()
      # half of 
      _minScale /= 1.5

    ###*
    # Ändert Position und Skalierung des Layers. Diesie Transformation erfolg in Form einer Animation.
    # Dies geschieht in folgenden Berechnungsschritten:
    # (1) Skalierungsfaktor wird bereinigt (darf nicht den zulässigen Bereich verlassen) 
    # (2) Erzeugung eines Grenz-Rechtecks (bounds), das die mögliche Positionierung des Layers vorgibt
    # (3) Gewährleisten, dass die neue Position innerhalb des zuvor gesetzten Rechtecks liegt 
    #     bzw. Zentrierung des Layers, falls das Bild die Stage nicht ganz ausfüllt
    # (4) Ausführen der Animation mit den zuvor berechneten Attributen
    # @private
    # @method _adjustLayer
    ###
    _adjustLayer = ->
      [stage, layer, image] = [viewer(), viewer().layer, viewer().image]
      # do not run this method if if pos or scale is not a number
      return if isNaN(scope.position.x) or isNaN(scope.position.y) or isNaN(scope.scale)
      # (1) keep scope within bounds 
      scope.scale = Math.min(Math.max(scope.scale, _minScale), _maxScale)
      # (2) define viewport bounds
      bounds =
        x1: -image.width()  + (stage.width()-_boundsWhitespace)/scope.scale
        y1: -image.height() + (stage.height()-_boundsWhitespace)/scope.scale
        x2: _boundsWhitespace/scope.scale
        y2: _boundsWhitespace/scope.scale
      # (3) clean position (keep it within bounds/centered)
      scope.position =
        x: Math.min(Math.max(scope.position.x, bounds.x1), bounds.x2)
        y: Math.min(Math.max(scope.position.y, bounds.y1), bounds.y2)
      # if in current context stage is wider than image
      if stage.width()/scope.scale >= image.width()+_boundsWhitespace*2
        # center group/image vertically move half of distance between image width and stage width
        scope.position.x = (stage.width()/scope.scale - image.width())/2
      # if in current context stage is higher than image
      if stage.height()/scope.scale >= image.height()+_boundsWhitespace*2
        # center group/image vertically move half of distance between image height and stage height
        scope.position.y = (stage.height()/scope.scale - image.height())/2
      # (4) perform animation
      # if new pos is different from current pos
      if scope.scale isnt layer.scaleX() or scope.position.x*scope.scale isnt layer.x() or scope.position.y*scope.scale isnt layer.y()
        # freeze state and destroy prior animation
        # !!! do not use finish() here, it'll cause adoptation of prior tween state !!
        # at least onFinish will be fired because after pause and destroy the tween is getting started again
        _adjustTween.pause().destroy() if _adjustTween
        # create position tween
        _adjustTween = new Kinetic.Tween
          x: scope.position.x*scope.scale
          y: scope.position.y*scope.scale
          scaleX: scope.scale
          scaleY: scope.scale
          node: layer
          duration: 0.25
          easing: Kinetic.Easings.EaseOut
          onFinish: ->
            # teile angular mit, dass scope modifiziert wurde
            scope.$apply()
        # start animation
        _adjustTween.play()

    ###*
    # Performs zoom to center
    # @private
    # @method _zoomToCenter
    # @param {Number} scale
    ###
    _zoomToCenter = (scale) ->
      # compute center point
      point =
        x: viewer().width()/2
        y: viewer().height()/2
      # perform the zoom
      _zoomToAbsolutePoint(scale, point)

    ###*
    # Performs zoom to point
    # @private
    # @method _zoomToAbsolutePoint
    # @param {Number} scale
    # @param {Object} absPoint Contains absolute x/y coordinates
    ###
    _zoomToAbsolutePoint = (scale, absPoint) ->
      [stage, layer] = [viewer(), viewer().layer]
      # (1) keep scale within bounds 
      scope.scale = Math.min(Math.max(scale, _minScale), _maxScale)
      # (2) translate point to local coordinates
      point = layer.getAbsoluteTransform().copy().invert().point(absPoint)
      # (3) set new position: current position minus distance between current scaled point and point with new scale
      scope.position =
        x: -point.x + absPoint.x/scope.scale
        y: -point.y + absPoint.y/scope.scale
      # (4) perform animation
      _adjustLayer()

    ###*
    # user clicks move up
    # @method moveUpClick
    ###
    scope.moveUpClick = ->
      scope.position.y += 100

    ###*
    # user clicks move down
    # @method moveDownClick
    ###
    scope.moveDownClick = ->
      scope.position.y -= 100

    ###*
    # user clicks move right
    # @method moveRightClick
    ###
    scope.moveRightClick = ->
      scope.position.x -= 100

    ###*
    # user clicks move left
    # @method moveLeftClick
    ###
    scope.moveLeftClick = ->
      scope.position.x += 100

    ###*
    # user clicks zoom in
    # @method zoomInClick
    ###
    scope.zoomInClick = ->
      _zoomToCenter(scope.scale + _changeScaleStep)

    ###*
    # user clicks zoom out
    # @method zoomOutClick
    ###
    scope.zoomOutClick = ->
      _zoomToCenter(scope.scale - _changeScaleStep)

    ###*
    # Moves layer so that image is centered vertically and horizontally
    # @method fitToScreenClick
    ###
    scope.fitToScreenClick = ->
      [stage, image] = [viewer(), viewer().image]
      scope.scale = _minScale

    ###*
    # @private
    # @method _scaleToSliderValue
    # @param scale {Number}
    # @return {Number} Scale 
    ###
    _scaleToSliderValue = (scale) ->
      # Prozentuales Verhältnis vom Abstand zwischen Scale und _minScale zu Abstand zwischen maxScale und _minScale
      return parseInt(((scale-_minScale)/(_maxScale-_minScale))*100)
    
    ###*
    # converts slider-value to image-scale
    # @private
    # @method _sliderValueToScale
    # @param sliderValue {Number}
    # @return {Number}
    ###
    _sliderValueToScale = (sliderValue) ->
      # Abstand zwischen _maxScale und _minScale mal sliderValue plus _minScale 
      return (_maxScale-_minScale) * (sliderValue/100) + _minScale

    ###*
    # @private
    # @method _scaleChange
    # @param newScale {Number}
    ###
    _scaleChange = ->
      scope.sliderValue = _scaleToSliderValue(scope.scale)
      _adjustLayer()

    ###*
    # @private
    # @method sliderValueChange
    ###
    scope.sliderValueChange = ->
      _zoomToCenter(_sliderValueToScale(scope.sliderValue))

    ###*
    # @private
    # @method _mouseWheel
    # @param e {Mouse-Event}
    ###
    _mouseWheel = (e) ->
      # first prevent default behavior 
      e.preventDefault()
      # get pointer position
      pos = viewer().getPointerPosition()
      # pointer position is defined (is not defined when window los focus)
      if pos
        # change scale
        if e.wheelDeltaY > 0
          scale = scope.scale + _changeScaleStep 
        else 
          scale = scope.scale - _changeScaleStep
        # we dont use scope.$apply here, adjust image do
        _zoomToAbsolutePoint(scale, pos)

    # Event-Binding
    viewer().on(Kinetic.MBCPanoramaViewer::IMAGE_READY, _adjustScaleBounds)
    viewer().on(Kinetic.MBCPanoramaViewer::SIZE_CHANGE, _resizeStage)
    viewer().layer.on('dragend', _stageDragend)
    scope.$watch('position', _adjustLayer, true) # true significa: check for object equality
    scope.$watch('scale', _scaleChange)
    angular.element(viewer().container()).on('mousewheel', _mouseWheel)

  # directive definitions
  directive =
    restrict: 'E'
    require: '^mbcPanoramaViewer'
    templateUrl: 'panoramacontrols.html'
    scope: 
      ###*
      # image-scale
      # @property scope.scale
      # @type Number 
      ###  
      scale: '='

      ###*
      # image-position in relative coordinates
      # @property scope.position
      # @type Object 
      ###   
      position: '='

      ###*
      # min image-scale
      # @property scope.minScale
      # @type Number 
      ###  
      minScale: '@'

      ###*
      # max image-scale
      # @property scope.minScale
      # @type Number 
      ### 
      maxScale: '@'

      ###*
      # on click an zoom-button or use of mwheel
      # image-scale will be incremented/decremented by this value
      # @property scope.minScale
      # @type Number 
      ### 
      changeScaleStep: '@'

    link: linkFunc
  # return directive
  return directive

angular.module('mbcPanoramaViewer')
.directive('mbcPanoramaControls', [panoramaControlsDirective])