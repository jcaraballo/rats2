package acceptance

import org.scalatest.{BeforeAndAfterEach, Spec}
import rats.{Arena, GamesRepository}
import io.shaka.http.Http.http
import io.shaka.http.Request.{POST, PUT, GET}
import io.shaka.http.Response
import io.shaka.http.Status.OK
import GameApiSpec.DoubleQuotableString

class GameApiSpec extends Spec with BeforeAndAfterEach {

  object `Game server must` {
    def `enable users to create games`() {
      val response: Response = http(POST(base + "/games"))
      assert((response.status, body(response)) === (OK, Some("""{"resource": "/games/1"}""")))
    }

    def `enable users to add players to an existing game`() {
      assert(okBody(http(POST(base + "/games"))) === """{"resource": "/games/1"}""")
      
      val bobPath = "/games/1/players/bob"
      val responseToBob = http(PUT(base + bobPath).entity("""{"board": [[1, 1], [1, 2]], "callback": "http://localhost:990/shots"}"""))
      assert((responseToBob.status, body(responseToBob)) === (OK, Some(s"{'resource': '$bobPath'}".dq)))
      
      val megPath = "/games/1/players/meg"
      val responseToMeg = http(PUT(base + megPath).entity("""{"board": [[2, 1], [2, 2]], "callback": "http://localhost:991/shots"}"""))
      assert((responseToMeg.status, body(responseToMeg)) === (OK, Some(s"{'resource': '$megPath'}".dq)))
    }

    def `enables users to shoot (response and forward pending)`() {
      assert(okBody(http(POST(base + "/games"))) === """{"resource": "/games/1"}""")
      assert(http(PUT(base + "/games/1/players/bob").entity( """{"board": [[1, 1], [1, 2]], "callback": "http://localhost:990/shots"}""")).status === OK)
      assert(http(PUT(base + "/games/1/players/meg").entity( """{"board": [[2, 1], [2, 2]], "callback": "http://localhost:991/shots"}""")).status === OK)

      assert(http(POST(base + "/games/1/shots").entity{ """{"shooter": "bob", "target": [1, 1]}"""}).status === OK)
    }

    // -- meta --

    def `identify itself`() {
      assert(okBody(http(GET(base + "/id"))) === "rats:" + arena.port)
    }
  }

  private def body(response: Response): Option[String] = response.entity.map(_.toString().trim)
  private def okBody(response: Response): String = {
    assert(response.status === OK)
    response.entityAsString.trim
  }

  override def beforeEach(){
    arena = new Arena(new GamesRepository()).start()
  }

  override def afterEach(){
    arena.stop()
  }

  var arena: Arena = _

  private def base = s"http://localhost:${arena.port}"
}

object GameApiSpec {
  // Work around https://issues.scala-lang.org/browse/SI-6476
  implicit class DoubleQuotableString(val s: String) extends AnyVal {
    def dq: String = s.replace('\'', '"')
  }
}