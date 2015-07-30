###*
# Erzeugt mit Hilfe von KineticJS eine Zeichenfläche (Kinetic.Stage) 
# mit einem Layer (kinetic.Layer) und einem Bildcontainer (Kinetic.Image)
# Erwartet eine Bild-Url, die über Parameter mit einem Event übergeben wird.
# Zeichnet dieses Bild dann im Bildcontainer.
# Benachrichtigt über einen ausgehenden Event darüber, 
# dass das Image im Bildcontainer ausgewechselt wurde.
# Ermöglicht Funktionserweiterungen durch Plugin-Initialisierung.
# Alle Plugininstanzen werden in einer internen Liste gehalten.
# Damit sollen Speicherlücken verhindert werden. 
# (Scope-Vriablen werden autmoatisch vom Garbage-Collector entfernt)
###
panoramaSelectionDirective = -> 
  ###*
  # @param {Kinetic.MBCPanoramaViewer} viewer PanoramaViewer-Instanz mit Stage, Layer und Image
  ###
  linkFunc = (scope, el, attrs, viewer) ->
    ###*
    # Contains transform controls enables moving and scaling capabilities to selection
    # @private
    # @property _transformControl
    # @type Kinetic.MBCTransformControlGroup
    ###
    _transformControl = undefined

    ###*
    # Group overlays part of the original panorama by a copy of the same panorama 
    # according to position and size of the transformation controls
    # @private
    # @property _overlayGroup
    # @type Kinetic.Group
    ### 
    _overlayGroup = undefined

    ###*
    # Is contained by {{#crossLink "_overlayGroup:attribute"}}{{/crossLink}}
    # Contains copy of original panorama
    # @private
    # @property _overlayImage
    # @type Kinetic.Image
    ### 
    _overlayImage = undefined

    ###*
    # @TODO Beschreibung
    # @private
    # @method _init
    # @param {Object} @TODO
    ###
    _init = ->
      # show image with half opacity to highlight rect with full opacity 
      viewer().image.opacity(0.5)
      # init transform control
      _transformControl = new Kinetic.MBCTransformControlGroup()
      # init overlay group
      _overlayGroup = new Kinetic.Group
        width:  viewer().width()
        height: viewer().height()
      # init  image
      _overlayImage = new Kinetic.Image()
      # add image an tranformation control to group
      _overlayGroup.add(_overlayImage)
      # add group and transformation control to layer
      viewer().layer.add(_overlayGroup)
                    .add(_transformControl)
      # bind events

    ###*
    # @private
    # @method _init
    ###
    _imageChange = (e) ->
      # set image
      _overlayImage.setImage(viewer().image.getImage())
      # set size of image
      _overlayImage.size
        width:  viewer().image.width()
        height: viewer().image.height()
      # adjust transform control
      _transformControl.setTransformRectAttributes
        position: scope.position
        size: scope.size
      _transformControl.setDragBounds
        x: viewer().image.x()
        y: viewer().image.y()
        width:  viewer().image.width()
        height: viewer().image.height()

    _transformRectChange = (e) ->
      scope.position = e.newVal.position
      scope.size =     e.newVal.size
      _adjustOverlayClip(e.newVal.position, e.newVal.size)

    _adjustOverlayClip = (pos, size) ->
      _overlayGroup.clip
        x: pos.x
        y: pos.y
        width:  size.width
        height: size.height
      viewer().draw()

    _transformAttributesChange = ->
      _transformControl.setTransformRectAttributes
        position: scope.position
        size:     scope.size

    # run init method
    _init() 
    # event binding
    viewer().on(Kinetic.MBCPanoramaViewer::IMAGE_READY, _imageChange)
    ###*
    # @TODO: 
    ###
    viewer().layer.on 'scaleXChange', (e) -> _transformControl.setAnchorScale(e.newVal)
    _transformControl.on(Kinetic.MBCTransformControlGroup::TRANSFORMRECT_CHANGE, _transformRectChange)   
    scope.$watch('[position,size]', _transformAttributesChange, true)

  # directive options
  directive =
    restrict: 'E'
    require: '^mbcPanoramaViewer'
    scope: 
      position: '='
      size: '='
    link: 
      pre: linkFunc
  # returns directive definition
  return directive

angular.module('mbcPanoramaViewer') 
.directive('mbcPanoramaSelection', [panoramaSelectionDirective]) 