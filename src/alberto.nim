# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import std/httpclient
import std/json
import std/[xmlparser, xmltree]
import std/unicode
import owlkettle
import std/options
import std/strutils


proc wordwrap(text: string): string =
  var list_of_words = text.split(" ")
  if list_of_words.len > 15:
    var count = 0
    var count2 = 0
    while count < list_of_words.len:
      if "\n" in list_of_words[count]:
        count2 = 0
      if count2 == 13:
        list_of_words.insert("\n", count)
      count += 1
      count2 += 1
  # rebuild text
  var new_text = ""
  for w in list_of_words:
    new_text = new_text & w & " "

  return new_text

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
    definition = definition & "\n" & $(i+1) & ". " & list[i].innerText

  definition = wordwrap(definition)
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
    sizeRequest: tuple[x, y: int] = (-1, -1)
    text: string = ""
    #wrapMode: WrapMode = WrapWord

  method view(app: AppState): Widget =
    #let isInActiveSearch = app.text != ""
    result = gui:
      Window():
        title = "Alberto - Dicionário Aberto"
        default_size = (600, 400)

        Grid:
          spacing = 6
          margin = 12
          Box(orient = OrientX, margin = 12, spacing = 6){.x:1, y:1, hExpand: true.}:
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



          ScrolledWindow{.x:1, y:2, vExpand: true.}:
            TextView:
              buffer = app.buffer
              monospace = false
              sizeRequest = app.sizeRequest


  let buffer = newTextBuffer()
  discard buffer.registerTag("marker", TagStyle(
      background: some("#ffff77"),
      weight: some(700)
  ))
  #buffer.text = ""


  brew(gui(App(buffer = buffer)))
