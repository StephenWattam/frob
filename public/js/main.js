
/* Handle drop-down search box. */
$(function() {
  var cache = {};
  $( "#search" ).autocomplete({
    minLength: 2,
    source: function( request, response ) {
        var term = request.term;
        if ( term in cache ) {
          response( cache[ term ] );
          return;
        }

        $.getJSON( "/search", request, function( data, status, xhr ) {
          cache[ term ] = data;
          response( data );
        });
      },
    select: function( event, ui ) {
        var id = $( "#search" ).val();
        fetch_card(id);
        $( "#search" ).val("");
      }
    });
});



/* Manage search query to fetch a card */
function fetch_card(id) {

  $.get( "/get/" + id, function( data ) {
    hide_card(id);
    $( "#content" ).prepend( data );
  });
}

/* Hide a card from the display */
function hide_card(id) {
  $( "#card-" + js_id( id ) ).detach();
}

/* Load the edit partial for a card */
function edit_card(id) {
  $.get( "/edit/" + id, function( data ) {
    hide_card(id);
    $( "#content" ).prepend( data );
  });
}

/* Deletes a card from the server */
function delete_card(id) {
    
  if (confirm("Delete card " + id + "?")){
    $.get( "/delete/" + id, function( data ) {
      hide_card(id);  
    });
  }
}

/* Discard edits. */
function discard_edits(id) {

  if (confirm("Discard edits?")){
    hide_card(id);
    fetch_card(id);
  }
}


/* Load the bookmark partial down the LHS */
function populate_bookmark_list() {
  $.get( "/bookmarks", function( data ) {
    $( "#bookmarks" ).html( data );
  });
}


/* Toggle the bookmarked status of the card ID */
function toggle_bookmark(id){

  $.get( "/toggle-bookmark/" + id, function( data ) {

    // The service echoes the ID it has bookmarked,
    // so check this.
    if (data == id){

      var marker = $( ".bookmark-marker-" + js_id(id) );

      if (marker) {
        if (marker.hasClass( 'fa-bookmark')){
          marker.removeClass( 'fa-bookmark' );
          marker.addClass( 'fa-bookmark-o' );
        }else{
          marker.removeClass( 'fa-bookmark-o' );
          marker.addClass( 'fa-bookmark' );
        }
      }
    }
 
    // Reload bookmark list
    populate_bookmark_list();
  });
}


/* Sanitise an ID to avoid having dots in. */
function js_id(id) {
  return ('' + id).replace(/\./g, '_');
}
