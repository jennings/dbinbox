;(function() {
  window.console ||
    (window.console = {
      log: function() {
        return {}
      }
    })

  $(function() {
    function getUploadRowHTML(filename, filesize, error) {
      if (filesize == null) {
        filesize = -1
      }
      if (error == null) {
        error = null
      }
      var row = $(
        '<tr class="template-upload">' +
          '<td class="filename-col col-sm-7">' +
          '<img class="sprite s_page_white_get" src="/img/icon_spacer.gif" />' +
          '<span class="name"></span>' +
          '<span class="size"></span>' +
          "</td>" +
          '<td class="info-col col-sm-4">uploading to Dropbox...</td>' +
          '<td class="status-col col-sm-1">' +
          '<img class="" src="/img/ajax-loading-small.gif" />' +
          "</td>" +
          "</tr>"
      )
      row.find(".name").text(filename)
      if (filesize !== -1) {
        row.find(".size").text(filesize)
      }
      if (error) {
        row.find(".error").text(error)
      }
      return row
    }

    function getDownloadRowHTML(file) {
      var row = $(
        '<tr class="template-download">' +
          '<td class="filename-col col-sm-7">' +
          '<img class="sprite s_page_white_get image_icon" src="/img/icon_spacer.gif" />' +
          '<span class="name"></span>' +
          '<span class="size"></span>' +
          "</td>" +
          '<td class="info-col col-sm-4"></td>' +
          '<td class="status-col col-sm-1">' +
          '<img class="sprite s_synced status_image" src="/img/icon_spacer.gif" />' +
          "</td>" +
          "</tr>"
      )
      row.find(".name").text(file.name)
      if (file.human_size) {
        row.find(".size").text("-" + file.human_size)
      }
      if (file.icon) {
        $(row.find("img.s_page_white_get")[0])
          .addClass("s_" + file.icon)
          .removeClass("s_page_white_get")
      }
      if (file.error) {
        console.log("there are errors in the file: ")
        console.log(file.error_message)
        console.log(file.error)
        row.find(".info-col").addClass("error").text(file.error)
        row.find(".status_image").removeClass("s_synced").addClass("s_error")
        row
          .find(".image_icon")
          .removeClass("s_page_white_get")
          .addClass("s_cross")
        console.log(file.error_class)
      }
      return row
    }

    $("#upload").fileupload({
      dataType: "json",
      autoUpload: true,
      acceptFileTypes: /./,
      uploadTemplateId: null,
      downloadTemplateId: null,
      uploadTemplate: function(o) {
        $(".instructions").hide()
        console.log("uploadTemplate")
        var rows = $()
        $.each(o.files, function(index, file) {
          console.log(file)
          console.log("filename = " + file.name)
          console.log("size = " + file.human_size)
          rows = rows.add(
            getUploadRowHTML(file.name, file.human_size, file.error)
          )
        })
        return rows
      },
      downloadTemplate: function(o) {
        console.log("downloadtemplate")
        console.log(o)
        var rows = $()
        $.each(o.files, function(index, file) {
          console.log("looping over o.files in downloadTemplate...")
          console.log(file)
          console.log("filename = " + file.name)
          console.log("size = " + file.bytes)
          if (file.error && file.error_class === "DropboxAuthError") {
            console.log("it's an authentication error!")
            $("#re-authenticate").show()
            $("#upload_button").addClass("disabled")
            $("#upload_button input").prop("disabled", true)
          }
          rows = rows.add(getDownloadRowHTML(file))
        })
        return rows
      }
    })

    $("#show_send_message").click(function() {
      $(this).fadeOut()
      $("#send_text").slideDown()
    })

    $("form#send_text").submit(function(e) {
      e.preventDefault()
      var form = $(this)
      var formData = form.serialize()
      $(".instructions").hide()
      var submitButton = form.children("input[type=submit]")[0]
      var previousSubmitButtonValue = submitButton.value
      submitButton.value = "Sending..."
      form
        .find("input, textarea")
        .addClass("disabled")
        .attr("disabled", "disabled")
      var filename = $("#timestamp").text()
      var filenameValue = $("#filename").val()
      if (filenameValue && filenameValue !== "") {
        filename += " " + filenameValue
      }
      filename += ".txt"
      var row = getUploadRowHTML(filename)
      $(".filelist .files").append(row)
      console.log(form.attr("action"))
      return $.post(form.attr("action"), formData, function(
        data,
        textStatus,
        jqXHR
      ) {
        console.log("text uploaded")
        form
          .find("input, textarea")
          .removeClass("disabled")
          .removeAttr("disabled")
        console.log(form)
        form[0].reset()
        submitButton.value = previousSubmitButtonValue
        $(row).replaceWith(getDownloadRowHTML(data[0]))
      })
    })

    $("#delete_confirmation").on("keyup", function(e) {
      if (this.value === "DELETE") {
        $("#delete_button").removeAttr("disabled").removeClass("disabled")
      }
    })

    $(document).bind("dragover", function(e) {
      var dropZone = $("#dropzone")
      var timeout = window.dropZoneTimeout
      $(".instructions").addClass("hover")
      if (!timeout) {
        dropZone.addClass("in")
      } else {
        clearTimeout(timeout)
      }
      if (e.target === dropZone[0]) {
        dropZone.addClass("hover")
      } else {
        dropZone.removeClass("hover")
      }
      window.dropZoneTimeout = setTimeout(function() {
        $(".instructions").removeClass("hover")
        window.dropZoneTimeout = null
        dropZone.removeClass("in hover")
      }, 100)
    })
  })
}.call(this))
