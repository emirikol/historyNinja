provinces = {};
map = null;
countries = $.getJSON(source+'/countries.json?7').then(function(d){ return d });
wars = $.getJSON(source+'/wars.json').then(function(d){ return d });
annals = $.getJSON(source+'/zipped_history.json?4').then(function(d){ return d });
current_time = parseInt($('#date').val());
$('label[for=date]').html(seconds_to_date(current_time)); 

function cache_provinces(list){
  var i = 0;
  for(var pid = list.pop();i < 25 && list.length > 0; pid = list.pop()) {
    if(!provinces[parseInt(pid)].path) {
      provinces[parseInt(pid)].path =  $('path[data-province='+pid+']', map);
      i += 1;
    }
  }
  // console.info(list.length);
  if(list.length > 0) {
    setTimeout(function(){ cache_provinces(list)  }, 20);
  } else {
    $('#loader').remove();
  }
}
    
    
var pan_zoom_options = {
  zoomScaleSensitivity: 0.5,
  minZoom: 0.75,
  maxZoom: 10,
  onPan: function(){
    if(zooming) {
      zooming = false;
    } else {
      pan = true;
    }
  },
  onZoom: function(){
    zooming = true;
    pan = false;
  },
  customEventsHandler: window.panZoomHandler
};

pan = false;
zooming = false;
map_loaded.then(function(){
    // map = this;//.contentDocument
    map  = $('svg');
    //$('path[fill="#fefefe"]', map).remove();
    svgPanZoom('svg',pan_zoom_options);
  
    $.getJSON(source+'/provinces.json?3').then(function(data){
      provinces = data;
      console.info('foobar');
      test = Object.keys(provinces);
      cache_provinces(test);
      update();
      if(window.location.href.match(/dev/)) {
        annals.then(function(){ $('#loader').remove()   });  
      }
      annals.then(function(events){ 
        var min = parseInt(events.filter(function(e){ return e.owner })[0].time);
        $('#date').attr('min', min).val(min).attr('max', parseInt(events.slice(0).reverse()[0].time));
      });  
    });
    
    
    // $('svg').css({height: '2000px'});
    
    $(map).on('click , touchend', 'path', function() {
      if (pan) return;
      var el = this;
      $.when(countries, wars).done(function(cs, ws) {
        var c = cs[$(el).attr('owner')];
        var p = provinces[$(el).data('province')];
        // $('.foo').text(c ? c.name : 'There be dragons');
        if(c) {
          $('.side-panel.country-info').removeClass('closed');
          $('.foo').html($('<a>').attr('target', '_blank').text(c.name).attr('href', 'https://en.wikipedia.org?search=' + c.name));
          $('[data-value="country.gov"]').text(c.gov);
          $('[data-value="country.suzerain"]').text(c.suzerain ? cs[c.suzerain].name : '');
          $('[data-value="country.clients"]').text(c.client ? c.client.map(function(s){ return cs[s].name }).join(', ') : '');
          $('[data-value="country.wars"]').text(c.war ? c.war.map(function(s){ return ws[s].name }).join(', ') : '');
          $('[data-value="country.ruler"]').text(c.monarch || 'N/A');
        } else {
          // $('.side-panel.country-info').addClass('closed');
          $('.foo').text('------');
          $('[data-value="country.gov"]').text('------');
          $('[data-value="country.suzerain"]').text('------');
          $('[data-value="country.clients"]').text('------');
          $('[data-value="country.wars"]').text('------');
          $('[data-value="country.ruler"]').text('------');
        }
        $('[data-value="province.culture"]').text(p ? p.culture.replace(/_/g, ' ') : '');
        $('[data-value="province.religion"]').text(p ? p.religion.replace(/_/g, ' ') : '');
      })
    }).on('click , touchend', function(e) {
      if (!pan && !$(e.target).is('path')) {
        $('.side-panel.country-info').addClass('closed');
        $('.foo').text('-----');
      }
      pan = false;
    });
  });
    
    
    function update() {
      var value = parseInt($('#date').val());
      if (value != current_time) {
        var diff = value - current_time;
        var step = 1 * 372
        if (Math.abs(diff / step) > 20) step *= 10;
        if (Math.abs(diff / step) > 20) step *= 10;
        var diff = Math.max(Math.min(diff, step), -step);
        var target = current_time + diff;
        progress(target);
        current_time = target;
        var year = Math.floor(target / 372);
        var month = Math.floor(target % 372 / 31 + 1);
        if (month < 10) month = '0' + month;
        $('label[for=date]').html(month + '.' + year);
        $('#date').trigger('change')
        setTimeout(update, 0)
      }
      else {
        setTimeout(update, 100)
      }
    }
    
    function seconds_to_date(seconds) {
      var year = Math.floor(seconds / 372);
      var month = Math.floor(seconds % 372 / 31 + 1);
      if (month < 10) month = '0' + month;
      return month + '.' + year;
    }
    
    function progress(target_time) {
      $.when(countries, annals).done(function(cs, an) {
        var delta = current_time < target_time ? 1 : -1;
        var index = current_time < target_time ? 0 : 1;
        var update_country_array_attr = function(country, attr, event){
          if(!event[attr]) return;
          if(!country[attr]) country[attr] = [];
          if(event[attr][index]) {
            country[attr].push(event[attr][index]) 
          } else {
            country[attr] = country[attr].filter(function(c){ return c != event[attr][index + delta] })
          }
        }
        var apply_event = function(event) {
          if(event.id) {
            var owner_code = delta > 0 ? event.owner : event.pre_owner;
            var owner = cs[owner_code] || {};
            $.each(event.id, function(i, e) {
              var id = parseInt(e);
              if (!provinces[id].path) provinces[parseInt(id)].path = $('path[data-province=' + id + ']', map);
              var province = provinces[parseInt(id)];
              if(event.culture) province.culture = event.culture[index];
              if(event.religion) province.religion = event.religion[index];
              if(event.owner) province.path.attr('owner', owner_code).css('fill', owner.color || '#999999');
            });
          } else {
            var country = cs[event.code];
            if(event.gov) country['gov'] = event.gov[index];
            if(event.monarch) country['monarch'] = event.monarch[index];
            if(event.suzerain) {
             country['suzerain'] = event.suzerain[index];
             var color = country['suzerain'] ? cs[country['suzerain']].color : country.color;
             $('path[owner='+event.code+']').css('fill', color);
            }
            update_country_array_attr(country, 'client', event);
            update_country_array_attr(country, 'war', event);
          }
        };

        if (delta < 0) an = an.slice(0).reverse();
        for (var i = 0;
          (target_time - current_time) * delta > 0; i += 1) {
          var event = an[i];
          if ((current_time - event.time) * delta > 0) continue;
          current_time = event.time;
          apply_event(event, delta);
        }
      });
    }
    
    
    
  // $('#date').qtip({
  //   content: {text: ''},
  //   position: {
  //     target: 'mouse',
  //     my: 'bottom center'
  //   }
  // }).on('mousemove', function(e){ 
  //   var min = parseInt($('#date').attr('min'))
  //   var time = (parseInt($('#date').attr('max')) - min) * (e.offsetX / $('#date').width())
  //   $(this).qtip('option', 'content.text', seconds_to_date(time) );
  // });
   $('#date').on('keydown', function(e) {
     if (e.shiftKey) $(this).attr('step', 3720);
     if (e.ctrlKey) $(this).attr('step', 31);
     if (e.altKey) $(this).attr('step', 37200);
   }).on('keyup', function(e) {
     $(this).attr('step', 372)
   }).focus();

   $('[data-toggle=editor]').click(function() {
     $('body').toggleClass('edit');
     $(this).toggleClass('active', $('body').is('.edit'));
   });
   
   
  

  settings = [
    o_O.model({
      path: 'country.ruler',
      name: 'Ruler',
      state: "on"
    }),
    o_O.model({
      path: 'country.gov',
      name: 'Goverment',
      state: "off"
    }),
    o_O.model({
      path: 'country.wars',
      name: 'Wars',
      state: "off"
    }),
    o_O.model({
      path: 'country.suzerain',
      name: 'Suzerain',
      state: "off"
    }),
    o_O.model({
      path: 'country.clients',
      name: 'Client States',
      state: "off"
    }),
    o_O.model({
      path: 'province.culture',
      name: 'Culture',
      state: "off"
    }),
    o_O.model({
      path: 'province.religion',
      name: 'Religion',
      state: "on"
    })
  ];

  $.each(settings, function(i, s){
    o_O.bind(s, $('#templates #data_row > *').clone().replaceAll('[data-path='+s.path+']') )
  });



  // function apply_settings() {
  //   $('.hinter').toggle(settings.show_slider_hint);
  //   $('[name=show_slider_hint]').prop('checked', settings.show_slider_hint); //initial load
  //   $.each(settings,function(k,v){
  //     $('[data-value="'+k+'"]').closest('tr').toggleClass('off', !v)
  //   });
  // };
  // $('[name=show_slider_hint]').change(function() {
  //   settings.show_slider_hint = $(this).is(':checked');
  //   localStorage['settings'] = JSON.stringify(settings);
  //   apply_settings();
  // });
  // $('[name*=settings]').change(function() {
  //     var name = $(this).attr('name');
  //     var test = $('[name="'+name+'"][value=on]').is(':checked');
  //     var key = name.split(':')[1]
  //     settings[key] = test;
  //     apply_settings();
  // });
  // apply_settings();
   
   