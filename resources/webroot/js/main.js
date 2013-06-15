// Main JS routines for frob
// Maintain lists of categories etc for the accordion
var category_accordion = null;


// Maintain a list of open notes
var open_notes = []
var notes = []
var categories = []

// Make a request to the server, handling error conditions.
function request(action, args, fn){
  
  // FIXME: this doesn't handle network error, i.e. the server being down

  $.getJSON('frob/' + action, {params: JSON.stringify(args)}, function(data){
    
    if(data['error']){
      $('#error_dialog_msg').html(data['error']);
      $('#error_dialog').show();
    }else{
      fn(data['success']);
    }
  });
}


// Add a whole category
// TODO: merge with existing data there
// TODO: sort
function add_category(name, note_list){

  categories[name] = $.guid++;
  category_accordion.prepend("<div class='category_container'><h3 class='category_header' id='ah_" + categories[name] + "'>" + name + "</h3><div><ul id='al_" + categories[name] + "'></ul></div></div>");

  $.each(note_list, function(index, note){
    add_note_to_ui(name, note['id'], note['title']);
  });

  category_accordion.accordion('refresh');
}


// Add a note to the category list down the side
// (and the rest of the ui)
// TODO: merge
// TODO: delete button on each one
function add_note_to_ui(category, id, title){

  notes[id] = {'title' : title, 'sync' : false}

  // TODO: sorted insert into list
  $('#al_' + categories[category]).append("<li id='nli_" + id + "'>" + title + "</li>");

  // FIXME: only add this handler once, somehow (right now it's firing many times)
  $('#al_' + categories[category]).click(function(){
    show_note(id);
  });
}

// Loads and shows a note to the user
function show_note(id){

  // TODO: load into open_notes (or scroll to one if it's open)
  // TODO: load from AJAX
  // TODO: compose note template and insert into DOM

  // Load from AJAX
  request('get_note', [id], function(note){

    $('#notes').prepend( compose_note_html(note) )

  });


}

// TODO: functionining buttons behaving with IDs
// TODO: editableness.
function compose_note_html(note){

  str = '<div class="note"> \
          <div class="note_front"> \
              <div class="note_tools"> \
                <a href="#" class="btn_delete_note"><img src="img/delete.png"/></a> \
                <a href="#" class="btn_edit_note"><img src="img/edit.png"/></a> \
                <a href="#" class="btn_close_note"><img src="img/close.png"/></a> \
              </div> \
              <h3>';
              
  str += note['name'];

  str += '</h3> \
              <div class="note_body">';

  str += note.html_text;

  str += '</div> \
              <div class="note_categories">';

  $.each(note['categories'], function(index, category_name){
    str += '<span class="note_category">' + category_name + '</span>'
  });

  str += '</div> \
              </div> ';

              /* TODO: editing 
              \
            <div class="note_edit">
              <input type="text" class="edit_note_title" value=>
              <textarea class="edit_note_body"></textarea>
              <input type="text" class="edit_note_categories"/>
              <button class="note_edit_button">Submit</button>
              <button class="note_edit_button">Cancel</button>
            </div>
            */
  str += '</div>';

  return str;
}


// ------------------------------------------------------------------
// Pullup functions for JQuery
//
$(document).ready(function(){

  // Test
  $('#test1').click(function(){
    request('notes_by_category', {}, function(categories){ 
      
      $.each(categories, function(k, v){
        add_category(k, v);
      });
    
    });
  });
  
  // Hide error dialog when clicked
  $('#error_dialog').click(function(){
     $(this).hide()
  });

  // Set up guid
  $.guid = 0

  // Set this up for others
  category_accordion = $('#categories_container');


});
