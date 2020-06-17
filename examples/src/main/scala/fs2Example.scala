// Example: Statefully transforming streams with fs2.

// We often wish to statefully transform one or more streams in some way, possibly
// evaluating effects as we do so. As an example, consider taking just the
// first _n_ elements of a [`Stream`](fs2/Stream.html).
import fs2._

object TransformingStreams {

  // Let’s look at an implementation of take using the scanChunksOpt combinator:
  def take[F[_], O](n: Long): Pipe[F, O, O] =
    // Here we create an anonymous function from `Stream[F,O]` to `Stream[F,O]` and we call
    // scanChunksOpt passing an initial state of n and a function which we define on
    // subsequent lines. The function takes the current state as an argument,
    // which we purposefully give the name n, shadowing the n defined in the signature of tk,
    // to make sure we can’t accidentally reference it.
    in =>
      in.scanChunksOpt(n) { n =>
        // If the current state value is 0 (or less), we’re done so we return None.
        // This indicates to scanChunksOpt that the stream should terminate.
        if (n <= 0) None
        else
          // Otherwise, we return a function which processes the next chunk in the stream.
          // The function first checks the size of the chunk. If it is less than the number
          // of elements to take, it returns the chunk unmodified, causing it to be output
          // downstream, along with the number of remaining elements to take from subsequent
          // chunks (n - m). If instead, the chunks size is greater than the number of elements
          // left to take, n elements are taken from the chunk and output, along with an
          // indication that there are no more elements to take.
          Some(c =>
            c.size match {
              case m if m < n => (n - m, c)
              case m          => (0, c.take(n.toInt))
            }
          )
      }

  println {
    Stream(1, 2, 3, 4).through(take(2)).toList
  }

}
