"""
<div id="data_panel">
  <div data-bind="class: [state(), key(), 'side-panel'].join(' ')">
    <div class='header'>
      <label data-bind="text: value()">-----</label>
      <label class="editor" data-bind="text: name()"></label>
    </div>
    <table class='table'>
    </table>
  </div>
"""

"""
  <tbody id="data_row">
    <tr data-bind="class: this().state()">
      <th data-bind="text: name()"></th>
      <td data-bind='text: value()'></td>
      <td class="editor">
        <div class="btn-group" data-toggle="buttons">
          <label data-bind="class: (this().state() == 'on' ? 'active' : '') + ' btn btn-xs btn-default'" >
            <input type="radio" data-bind="name: path(); value: state" value="on"> Show
          </label>
          <label data-bind="class: (this().state() == 'off' ? 'active' : '') + ' btn btn-xs btn-default'">
            <input type="radio" data-bind="name: path(); value: state" value="off"> Hide
          </label>
        </div>
      </td>
    </tr>
  </tbody>
"""

# box = o_O.model({prov: o_O.model({x: 6}), cou: o_O.model({x: 2})});

class Arrow
  constructor: ->
    @province = o_O.model(path: null, id: null, culture: null, religion: null)
    @country = o_O.model(ruler: null, name: null, code: null, gov: null, wars: null, suzerain: null, client: null)
  current_country: ->
    this.country()
  current_province: ->
    this.province()
window['$current_record'] =  o_O.model(new Arrow(), Arrow.prototype);

class Attribute
  constructor: ({@model, @key, @name, @state}) ->
    @state ?= 'off'
    @format = null
  @model: (arg) ->
    model = o_O.model(new @(arg), @.prototype)
    model.format( arg.format ) if(arg.format)
    return model
  foobar: -> 
    $current_record[@model()]()[@key()]
  path: ->
    "#{@model()}.#{@key()}"
  _current_record: ->
    $current_record[@model()]()

window.Attribute = Attribute
  
settings = [
  {    model: 'country',    key: 'monarch',     name: 'Ruler', state: "on"  },
  {    model: 'country',    key: 'gov',       name: 'Government' },
  {    model: 'country',    key: 'wars',      name: 'Wars', }, #format: -> { (@value()||[]).map((s)->{ $wars[s].name }).join(', ') : '' } },
  {    model: 'country',    key: 'suzerain',  name: 'Suzerain',  },
  {    model: 'country',    key: 'clients',   name: 'Client States',  },
  {    model: 'province',   key: 'culture',   name: 'Culture',  },
  {    model: 'province',   key: 'religion',  name: 'Religion',  }
];
#$('[data-value="country.suzerain"]').text(c.suzerain ? cs[c.suzerain].name : '');
#$('[data-value="country.clients"]').text(c.client ? c.client.map(function(s){ return cs[s].name }).join(', ') : '');
#$('[data-value="country.ruler"]').text(c.monarch || 'N/A');
#$('[data-value="province.culture"]').text(p ? p.culture.replace(/_/g, ' ') : '');
#$('[data-value="province.religion"]').text(p ? p.religion.replace(/_/g, ' ') : '');

$.each(settings, (_, s) -> 
  row = $('#templates #data_row > *').clone().appendTo('.side-panel.country-info table')
  o_O.bind(Attribute.model(s), row )
)
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