#= require jquery-2.1.3.min
#= require jquery_ujs
#= require bootstrap/affix
#= require bootstrap/alert
#= require bootstrap/button
#= require bootstrap/carousel
#= require bootstrap/collapse
#= require bootstrap/dropdown
#= require bootstrap/modal
#= require bootstrap/scrollspy
#= require bootstrap/tab
#= require bootstrap/transition
#= require bootstrap/tooltip
#= require bootstrap/popover
#= require_directory .

$ ->
  $('input[type="date"]').datepicker
    format: 'yyyy-mm-dd'
    orientation: "top left"
  $('#_search').change ->
    $this = $(this)
    if $this.val().length > 0
      $this.addClass("not-empty")
    else
      $this.removeClass("not-empty")
