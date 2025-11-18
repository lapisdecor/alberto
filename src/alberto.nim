# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import std/httpclient
import std/json
import std/[xmlparser, xmltree]
import std/unicode
import owlkettle


proc do_search(word: string): string =
# search the word
  echo "Searching... " & word
  if word == "":
    return "Por favor escrever uma palavra."
  var definition = ""
  var response = ""
  var client = newHttpClient()
  var jump = false
  try:
    response = client.getContent("https://api.dicionario-aberto.net/word/" & toLower(word))
    #echo response
    if response == "[]" or response == "":
      definition = "A palavra não está no dicionário"
      jump = true
  finally:
    client.close()

  if jump:
    return definition

  let myJson = parseJson(response)

  var myXML = myJson[0]["xml"].getStr()
  var x = parseXml(myXML)
  var list = x.findAll("def")
  let k = list.len() - 1

  for i in 0..k:
    definition = definition & $(i+1) & ". " & list[i].innerText

  return definition


when isMainModule:
  echo("Bem vindo ao Alberto, a versão Gtk do dicionário aberto!")

  # main application
  viewable App:
    searchDelay: uint = 100
    word: string
    placeholderText: string
    buffer: TextBuffer
    monospace: bool
    text: string = ""
    #wrapMode: WrapMode = WrapWord

  method view(app: AppState): Widget =
    #let isInActiveSearch = app.text != ""
    result = gui:
      Window():
        title = "Alberto - Dicionário Aberto"
        default_size = (600, 100)

        Box(orient = OrientY, margin = 0, spacing = 6):

          Box(orient = OrientX, margin = 12, spacing = 6):
            Label(text = "Termo")
            SearchEntry:
              text = app.text
              placeholderText = "palavra"
              searchDelay = app.searchDelay

              proc activate() =
                app.buffer.text = do_search(app.text)

              proc changed(searchString: string) =
                app.text = searchString

            Button(text = "Pesquisar"):

              proc clicked() =
                app.buffer.text = do_search(app.text)



          Box(orient = OrientY, margin = 12, spacing = 6):
            TextView:
              buffer = app.buffer
              monospace = false


  let buffer = newTextBuffer()

  buffer.text = ""


  brew(gui(App(buffer = buffer)))
