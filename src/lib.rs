#![no_std]

#[derive(Clone)]
/// A queue holding **N-1** elements.
///
/// Why N-1? Because [T; N+1] isn't supported, and ringbuffers/circular buffers
/// generally waste 1 element in an optimal implementation.
/// https://github.com/rust-lang/rust/issues/76560
pub struct Queue<T, const N: usize> {
    array: [T; N],
    read: usize,
    write: usize,
}

impl<T, const N: usize> Queue<T, N>
where
    T: Default + Copy,
{
    pub fn new() -> Self {
        Self {
            array: [T::default(); N],
            read: 0,
            write: 0,
        }
    }

    pub fn pop(&mut self) -> Option<T> {
        if self.read == self.write {
            return None;
        }
        let val = core::mem::take(&mut self.array[self.read]);
        self.read = self.inc_wrap(self.read);
        Some(val)
    }
}

impl<T, const N: usize> Default for Queue<T, N>
where
    T: Default + Copy,
{
    fn default() -> Self {
        Self::new()
    }
}

impl<T, const N: usize> Queue<T, N> {
    fn inc_wrap(&self, n: usize) -> usize {
        (n + 1) % N
    }

    pub fn push(&mut self, val: T) -> bool {
        let new_write = self.inc_wrap(self.write);
        if new_write == self.read {
            return false;
        }
        self.array[self.write] = val;
        self.write = new_write;
        true
    }

    pub fn pop_into(&mut self, out_val: &mut T) -> bool {
        if self.read == self.write {
            return false;
        }
        core::mem::swap(out_val, &mut self.array[self.read]);
        self.read = self.inc_wrap(self.read);
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_push_pop() {
        let mut q: Queue<u32, 4> = Queue::new();
        assert_eq!(q.pop(), None);
        assert!(q.push(1));
        assert!(q.push(2));
        assert!(q.push(3));
        // Should be full now, next push should fail
        assert!(!q.push(4));
        assert_eq!(q.pop(), Some(1));
        assert_eq!(q.pop(), Some(2));
        assert!(q.push(4));
        assert_eq!(q.pop(), Some(3));
        assert_eq!(q.pop(), Some(4));
        assert_eq!(q.pop(), None);
    }

    #[test]
    fn test_pop_into() {
        let mut q: Queue<u8, 3> = Queue::new();
        assert!(q.push(10));
        assert!(q.push(20));
        let mut out = 0;
        assert!(q.pop_into(&mut out));
        assert_eq!(out, 10);
        assert!(q.pop_into(&mut out));
        assert_eq!(out, 20);
        assert!(!q.pop_into(&mut out));
    }

    #[test]
    fn test_wrap_around() {
        let mut q: Queue<u16, 3> = Queue::new();
        assert!(q.push(100));
        assert!(q.push(200));
        assert_eq!(q.pop(), Some(100));
        assert!(q.push(300));
        assert_eq!(q.pop(), Some(200));
        assert_eq!(q.pop(), Some(300));
        assert_eq!(q.pop(), None);
    }

    #[test]
    fn test_default() {
        let mut q: Queue<u32, 3> = Queue::default();
        assert!(q.push(100));
        assert!(q.push(200));
        assert_eq!(q.pop(), Some(100));
        assert!(q.push(300));
        assert_eq!(q.pop(), Some(200));
        assert_eq!(q.pop(), Some(300));
        assert_eq!(q.pop(), None);
    }

    #[test]
    fn test_push_into_full() {
        let mut q: Queue<u32, 2> = Queue::new();
        assert!(q.push(1));
        assert!(q.pop().is_some());
        assert!(q.push(1));
        assert!(!q.push(1));
    }

    #[test]
    fn test_pop_from_empty() {
        let mut q: Queue<u32, 5> = Queue::new();
        assert!(q.pop().is_none());
    }
}
