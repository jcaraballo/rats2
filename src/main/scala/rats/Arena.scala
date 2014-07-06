package rats

import unfiltered.jetty.Http
import unfiltered.request._
import unfiltered.response._
import rats.extractors.AnInt

class Arena(val gamesRepository: GamesRepository, val specifiedPort: Option[Int] = None) {
  var httpServer: Http = _

  def start(): Arena = {
    val plan = unfiltered.filter.Planify {
      case GET(Path(Seg("id" :: Nil))) => ResponseString(s"rats:$port\n")
      case POST(Path(Seg("games" :: Nil))) => ResponseString("""{"resource": "/games/""" + gamesRepository.newGame() + "\"}\n")
      case PUT(Path(Seg("games" :: AnInt(gameId) :: "players" :: playerId :: Nil))) =>
        val resource = s"/games/$gameId/players/$playerId"
        ResponseString("""{"resource": """" + resource + "\"}\n")
      case POST(Path(Seg("games" :: AnInt(gameId) :: "shots" :: Nil))) => ResponseString("TBD")
    }

    httpServer = (specifiedPort match {
      case Some(p) => unfiltered.jetty.Http(p)
      case None => unfiltered.jetty.Http.anylocal
    }).filter(plan).start()

    println("Server started on port " + port)
    this
  }

  def port: Int = {
    httpServer.port
  }

  def stop() {
    httpServer.stop()
  }

  def join() {
    httpServer.join()
  }
}

object Arena {
  def main(args: Array[String]){
    val port: Some[Int] = if (args.length>0) Some(args(0).toInt) else Some(8080)
    new Arena(new GamesRepository(), port).start().join()
  }
}