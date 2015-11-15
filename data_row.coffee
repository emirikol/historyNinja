"""
-- province_panel
  <div class='side-panel province-info {{ state }}'>
    <div class='header'>
      <label data-value="grr">Province</label>
      <label class="editor">Country</label>
    </div>
    <table class='table'>
      <tbody></tbody>
    </table>
  </div>
-- country_panel
  <div class='side-panel country-info {{ state }}'>
    <div class='header'>
      <label data-value="grr">{{ formatted_value }}</label>
      <label class="editor">Country</label>
    </div>
    <table class='table'>
      <tbody></tbody>
    </table>
  </div>
-- 

  
-- data_row  
 <tr class="{{state}}">
   <th>{{name}}</th>
   <td data-value="grr">{{formatted_value}}</td>
   <td class="editor">
    <div class="btn-group" data-toggle="buttons">
      <label class="{{ string_if 'active' is_checked  }} btn btn-xs btn-default" >
        <input type="radio" name="{{path}}" value="on" {{ string_if 'checked' is_checked  }}> Show
      </label>
      <label class="{{ string_unless 'active' is_checked }} btn btn-xs btn-default" >
        <input type="radio" name="{{path}}" value="off" {{ string_unless 'checked' is_checked  }}> Hide
      </label>
    </div>
   </td>
 </tr>
"""

Deps = Package.deps.Deps;
bind = (fn, me) -> -> fn.apply me, arguments

UI.registerHelper 'string_unless', (string, bool) ->
  if bool then '' else string
UI.registerHelper 'string_if', (string, bool) ->
  if bool then string else ''


Model = (obj) ->
   model = {} 
   $.each(obj, (k,inital_val)->
      if(typeof inital_val== "function") 
       model[k] = inital_val
       return
      model[k] = attribute = (new_val)->
        if(typeof new_val == "undefined") 
          attribute._dep.depend()
          attribute._value
        else
          return new_val if (attribute._value == new_val)
          attribute._dep.changed();
          attribute._value = new_val
      attribute._dep = new Deps.Dependency
      attribute._value = inital_val
   )
   $.each(obj.constructor.prototype, (k,v)->
     model[k] = bind(v, model);
   )
   model
window.Model = Model

class Arrow
  constructor: ->
    @province = Model(path: null, id: null, culture: null, religion: null)
    @country  = Model(monarch: null, name: null, code: null, gov: null, war: null, suzerain: null, client: null, color: null)
  current_country: ->
    this.country()
  current_province: ->
    this.province()
window['$current_record'] =  Model(new Arrow());

class Attribute
  constructor: ({@model, @key, @name, @state, @format, @default}) ->
    @state ?= 'off'
    @format ?= (val)-> val;
  value: -> 
    @_current_record()[@key()]?() || @default()
  formatted_value: ->
    @format(@value())
  path: ->
    "#{@model()}.#{@key()}"
  is_checked: -> 
    @state() == 'on'
  _current_record: ->
    $current_record[@model()]()

window.Attribute = Attribute
  

country_panel = Model(new Attribute(model: 'country',    key: 'name', state: "on", default: "--------"))
UI.insert(UI.renderWithData(Template.country_panel, country_panel), $('.side-bar')[0]) 

province_panel = Model(state: 'on')
UI.insert(UI.renderWithData(Template.province_panel, country_panel), $('.side-bar')[0]) 

#{ (v||[]).map((s)->{ $wars[s].name }).join(', ') : '' } 
row_settings = [
  {    model: 'country',    key: 'monarch',     name: 'Ruler', state: "on"  },
  {    model: 'country',    key: 'gov',       name: 'Government' },
  {    
       model: 'country',    key: 'war',      name: 'Wars',
       format: (v)-> (v||[]).map((s)->$wars[s].name).join(', ')
  },
  {    model: 'country',    key: 'suzerain',  name: 'Suzerain',  },
  {    model: 'country',    key: 'client',   name: 'Client States',  },
  {    model: 'province',   key: 'culture',   name: 'Culture',  state: "on"},
  {    model: 'province',   key: 'religion',  name: 'Religion',  }
];
#$('[data-value="country.suzerain"]').text(c.suzerain ? cs[c.suzerain].name : '');
#$('[data-value="country.clients"]').text(c.client ? c.client.map(function(s){ return cs[s].name }).join(', ') : '');
#$('[data-value="country.ruler"]').text(c.monarch || 'N/A');
#$('[data-value="province.culture"]').text(p ? p.culture.replace(/_/g, ' ') : '');
#$('[data-value="province.religion"]').text(p ? p.religion.replace(/_/g, ' ') : '');

Template.data_row.events(
  'click label': (evt, tmpl) -> 
    tmpl.data.state( $(evt.target).find('input').val() ) 
    true
)

$.each(row_settings, (_, s) -> 
  target = $(".side-panel.#{s.model}-info tbody")[0]
  UI.insert(UI.renderWithData(Template.data_row, Model(new Attribute(s))), target) 
)
$coffee.resolve()
###  
$.each(settings, function(i, s){
  o_O.bind(s, $('#templates #data_row > *').clone().replaceAll('[data-path='+s.path+']') )
});
###
    
    
###
model
attribute
record
settings

settings->model->attribute->VALUE
model->record->attribute->VALUE

# single model approach
Settings | global
 
Box
  *record
  ?model

Attribute
  ?model, key, name, state
  name
  current_record
  settings
  #setting_value
  #record_value
  
current_province = Box.new('province')
current_province.attribute_watcher('foobar')

#two-model approach
function meta_template(model, attribute) {
  return function template(box) {
    ...
  } 
}

meta('province', 'foobar')(current_provice)

#but I could theortically create a box register and be fine with
meta('province', 'foobar') =>
  template('province', 'foobar').bind(Register['province'])
  
# I kind of wonder how it would look explicitly written...
###