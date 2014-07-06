package rats

import java.util.concurrent.atomic.AtomicInteger


class GamesRepository {
  private val atomicInteger = new AtomicInteger()
  def newGame(): Long = atomicInteger.incrementAndGet()
}