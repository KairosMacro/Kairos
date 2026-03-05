class dweet {
   __New(name) {
      this.name := name
      this.baseUrl := "https://dweet.cc"
      this.lastMessage := 0
      ; maybe add encryption later ? "this.salt := [string]"
   }

   SendMessage(str) {
      url := this.baseUrl "/dweet/for/" this.name "?json=" this.Encode(str)

      try {
         wr := ComObject("WinHttp.WinHttpRequest.5.1")
         wr.Open("GET", url, false)
         wr.Send()
         return wr.ResponseText
      } catch as e
         return "Error: " e.Message
   }

   ReceiveMessage(ignoreOld := 20) {
      url := this.baseUrl "/get/latest/dweet/for/" this.name
      try {
         wr := ComObject("WinHttp.WinHttpRequest.5.1")
         wr.Open("GET", url, false)
         wr.Send()
         msg := wr.ResponseText
      } catch as e
         return ""
      
      try {
         data := JSON.parse(msg)
      } catch
         return ""

      if (!data.Has("with") || data["with"].Length < 1)
         return ""

      msg := data["with"][1]["content"]
      if (!msg.Has("json"))
         return ""
      msg := msg["json"]
      try {
         msg := JSON.parse(msg)
      } catch
         return ""
      
      if (IsObject(msg) && msg.Has("timestamp")) { ; just to check that it's not the same message
         time := msg["timestamp"]
         if (time <= this.lastMessage)
            return ""
         this.lastMessage := time
         return msg
      }
      return ""
   }

   Encode(str) {
      buff := Buffer(StrPut(str, "UTF-8"))
      StrPut(str, buff, "UTF-8")
      encoded := ""
      Loop buff.Size - 1 {
         byte := NumGet(buff, A_Index - 1, "UChar")
         char := Chr(byte)

         if (byte >= 128 || RegExMatch(char, "[^A-Za-z0-9\-_.~]")) {
            encoded .= "%" Format("{:02X}", byte)
         } else {
            encoded .= char
         }
      }
      return encoded
   }
}
