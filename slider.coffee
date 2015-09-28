class Slider
  constructor: (elem) ->
    [@preview, @input] = [elem.find('.preview'), elem.find('input')]
    @selection().draggable(
      containment: 'parent',
      scroll: 'false'
      drag: @selection_changed
    )
    [@scale, @position] = [1.0, 0]
    @input.on('change', @set_marker)#@set_preview)
    @preview.on('wheel', @set_scale)
    @set_preview()
  
  selection: =>
    @preview.find('.selection')
  marker: =>
    @preview.find('.marker')
    
  set_preview: ->
    @selection().css(width: "#{@scale * 100}%")
    @input.css(width: "#{100 / @scale}%")
    
  selection_changed: (event, ui) =>
    @set_input ui.position.left
    
  set_input: (left) =>
    offset = left / @preview.width() * 100 * (1/@scale)
    @input.css('margin-left', "-#{offset}%")
    
  set_marker: =>
    min = parseInt(@input.attr('min'))
    percent = (parseInt(@input.val()) - min) / (parseInt(@input.attr('max')) - min) * 100
    @marker().css(left: "#{percent}%")
  
  set_scale: (event) => 
    scale = @scale + event.originalEvent.wheelDeltaY * -0.0001
    @scale = Math.max(Math.min(scale , 1), 0.1)
    @set_preview()
    @set_input @selection().position().left 
    
window.Slider = Slider
window.slider = new Slider($('.slider'));