<!DOCTYPE html>
<html>
<head>
 <title>${redirection_target}</title>
</head>
<body>
  <p>You are being redirected to <a href="https://${redirection_target}">https://${redirection_target}</a> in 5 seconds, or click <a href="https://${redirection_target}">here</a>.</p>
  <script type="text/javascript">
    var currentPath = window.location.pathname + window.location.search + window.location.hash;
    var redirectTarget = "https://${redirection_target}" + currentPath
    function redirectToTarget() {
      window.location.href = redirectTarget;
    }
    function printParagraph(){
      var paragraph = document.createElement("p");
      var message = document.createTextNode("You are being redirected to ");
      paragraph.appendChild(message)
      var link = document.createElement("a");
      link.setAttribute("href", redirectTarget);
      var linkText = document.createTextNode(redirectTarget);
      link.appendChild(linkText);
      paragraph.appendChild(link)
      var message2 = document.createTextNode(" in 5 seconds, or click ");
      paragraph.appendChild(message2)
      var link2 = document.createElement("a");
      link2.setAttribute("href", redirectTarget);
      var linkText2 = document.createTextNode("here");
      link2.appendChild(linkText2);
      paragraph.appendChild(link2)
      document.body.innerHTML = ''; // Clear existing content
      document.body.appendChild(paragraph);
    }
    printParagraph();
    setTimeout(redirectToTarget, 5000);
  </script>
</body>
</html>
