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
# 
# @class Kinetic.MBCPanoramaViewer
# @extends Kinetic.Stage
###
class Kinetic.MBCPanoramaViewer extends Kinetic.Stage
  ###*
  # Benachritigt Observer, dass andere Bild geladen werden soll
  # @event Kinetic.MBCPanoramaViewer::IMAGE_CHANGED
  # @param {Event} e Event object
  # @param {String} e.newVal Neue Bildadresse
  # @param {String} e.oldVal Alte Bildadresse
  ###
  IMAGE_CHANGE: 'imageUrlChange'

  ###*
  # Benachritigt Observer, dass Bild ausgetauscht wurde
  # @event Kinetic.MBCPanoramaViewer::IMAGE_CHANGED
  ###
  IMAGE_READY: 'imageReady'

  ###*
  # Benachritigt Observer, dass Bild ausgetauscht wurde
  # @event Kinetic.MBCPanoramaViewer::IMAGE_CHANGED
  ###
  SIZE_CHANGE: 'widthChange heightChange'

  ###*
  # initialisiert properties und stage 
  # Ruft {{#crossLink "____init:method"}}{{/crossLink}} auf
  # @method contructor
  # @param {HTML-Element} container HTML-Element, in welchem der Panroamaviewer erzeug werden soll
  # @return {Kinetic.MBCPanoramaViewer}
  ###
  constructor: (container) ->
    ###*
    # Layer contains the group that contains panorama image
    # @property layer
    # @type Kinetic.Layer
    ###
    @layer = undefined

    ###*
    # The panorama image
    # @property image
    # @type Kinetic.Image
    ###
    @image = undefined

    # init stage
    super
      container: container
      width:  container.clientWidth
      height: container.clientHeight

    # run contructor method  
    return @____init(container)

  ###*
  # Erzeugt stage auf dem Zielcontainer-Element
  # Legt Layer in die Stage und leeres Image in den Layer
  # Bindet Change-Image-Event
  # @method ____init
  # @param {HTML-Element} container HTML-Element, in welchem der Panroamaviewer erzeug werden soll
  # @return {Kinetic.MBCPanoramaViewer}
  ###
  ____init: (container) ->
    # init layer
    @layer = new Kinetic.Layer
      draggable: true
    # init image
    @image = new Kinetic.Image
      width:  @width()
      height: @height()
    # add image and layer to stage
    @layer.add(@image)
    @add(@layer)
    # bind events
    @on(@IMAGE_CHANGE, (e)=>@_imageChanged(e))
    # return stage so other modules can hook into event system
    return @

  ###*
  # Erzeugt leeres Image und bindet onload-Event bevor es den Ladevorgang der übergebenen Bild-Url initiert
  # Wird ausgelöst durch das Ereignis:
  # {{crossLink "IMAGE_CHANGE:event"}}{{/crossLink}}
  # @private
  # @method _imageChanged
  # @param {Object} e Event object
  # @param {String} e.newVal Image-Url
  ###
  _imageChanged: (e) ->
    # replace with new image
    img = new Image()
    # bind onload event 
    img.onload = (e)=>@_imageLoaded(e)
    # start image loading 
    img.src = e.newVal

  ###*
  # Replaces panorama by new picture.
  # Triggers event to signal that picture was just replaced: 
  # {{crossLink "IMAGE_READY:event"}}{{/crossLink}}
  # @private
  # @method _imageLoaded
  # @param {Object} e Event object
  # @param {Image-Element} e.srcElement Image-Element
  ###
  _imageLoaded: (e) ->
    el = e.srcElement
    # set image
    @image.setImage(el)
    # size image by width
    @image.size
      height: el.height
      width:  el.width
    # improve performance
    @image.cache()
    # redraw layer
    @layer.draw()
    # trigger image changed
    @fire(@IMAGE_READY)

###*
# @method setImageUrl
# @param {String} imageUrl Bildadresse
# @return {Kinetic.MBCPanoramaViewer}
###
Kinetic.Factory.addSetter(Kinetic.MBCPanoramaViewer, 'imageUrl')