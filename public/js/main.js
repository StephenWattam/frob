
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

  /** TODO
   * * Delete existing card if they exist with the same ID
   * * Fetch card HTML using AJAX
   * * Render card.
   */

  $.get( "/get/" + id, function( data ) {
    $( "#content" ).append( data );
    alert( "Load was performed. (" + id + ")" );
  });
}


/* Load the bookmark partial down the LHS */
function populate_bookmark_list() {
  $.get( "/bookmarks", function( data ) {
    $( "#bookmarks" ).html( data );
  });
}


/* Toggle the bookmarked status of the card ID */
function toggle_bookmark(id, marker){

  $.get( "/toggle-bookmark/" + id, function( data ) {

    // The service echoes the ID it has bookmarked,
    // so check this.
    if (data == id){
      if (marker.hasClass( 'fa-bookmark')){
        marker.removeClass( 'fa-bookmark' );
        marker.addClass( 'fa-bookmark-o' );
      }else{
        marker.removeClass( 'fa-bookmark-o' );
        marker.addClass( 'fa-bookmark' );
      }
    }
 
    // Reload bookmark list
    populate_bookmark_list();
  });



}
