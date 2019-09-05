defmodule Mechanizex.HTTPAdapter.Httpoison do
  @behaviour Mechanizex.HTTPAdapter
  alias Mechanizex.{Request, Response, Page, Browser}
  alias Mechanizex.HTTPAdapter.NetworkError

  @posix_errors [
    e2big: "Too long argument list",
    eacces: "Permission denied",
    eaddrinuse: "Address already in use",
    eaddrnotavail: "Cannot assign requested address",
    eadv: "Advertise error",
    eafnosupport: "Address family not supported by protocol family",
    eagain: "Resource temporarily unavailable",
    ealign: "EALIGN",
    ealready: "Operation already in progress",
    ebade: "Bad exchange descriptor",
    ebadf: "Bad file number",
    ebadfd: "File descriptor in bad state",
    ebadmsg: "Not a data message",
    ebadr: "Bad request descriptor",
    ebadrpc: "Bad RPC structure",
    ebadrqc: "Bad request code",
    ebadslt: "Invalid slot",
    ebfont: "Bad font file format",
    ebusy: "File busy",
    echild: "No children",
    echrng: "Channel number out of range",
    ecomm: "Communication error on send",
    econnaborted: "Software caused connection abort",
    econnrefused: "Connection refused",
    econnreset: "Connection reset by peer",
    edeadlk: "Resource deadlock avoided",
    edeadlock: "Resource deadlock avoided",
    edestaddrreq: "Destination address required",
    edirty: "Mounting a dirty fs without force",
    edom: "Math argument out of range",
    edotdot: "Cross mount point",
    edquot: "Disk quota exceeded",
    eduppkg: "Duplicate package name",
    eexist: "File already exists",
    efault: "Bad address in system call argument",
    efbig: "File too large",
    ehostdown: "Host is down",
    ehostunreach: "Host is unreachable",
    eidrm: "Identifier removed",
    einit: "Initialization error",
    einprogress: "Operation now in progress",
    eintr: "Interrupted system call",
    einval: "Invalid argument",
    eio: "I/O error",
    eisconn: "Socket is already connected",
    eisdir: "Illegal operation on a directory",
    eisnam: "Is a named file",
    el2hlt: "Level 2 halted",
    el2nsync: "Level 2 not synchronized",
    el3hlt: "Level 3 halted",
    el3rst: "Level 3 reset",
    elbin: "ELBIN",
    elibacc: "Cannot access a needed shared library",
    elibbad: "Accessing a corrupted shared library",
    elibexec: "Cannot exec a shared library directly",
    elibmax: "Attempting to link in more shared libraries than system limit",
    elibscn: ".lib section in a.out corrupted",
    elnrng: "Link number out of range",
    eloop: "Too many levels of symbolic links",
    emfile: "Too many open files",
    emlink: "Too many links",
    emsgsize: "Message too long",
    emultihop: "Multihop attempted",
    enametoolong: "Filename too long",
    enavail: "Unavailable",
    enet: "ENET",
    enetdown: "Network is down",
    enetreset: "Network dropped connection on reset",
    enetunreach: "Network is unreachable",
    enfile: "File table overflow",
    enoano: "Anode table overflow",
    enobufs: "No buffer space available",
    enocsi: "No CSI structure available",
    enodata: "No data available",
    enodev: "No such device",
    enoent: "No such file or directory",
    enoexec: "Exec format error",
    enolck: "No locks available",
    enolink: "Link has been severed",
    enomem: "Not enough memory",
    enomsg: "No message of desired type",
    enonet: "Machine is not on the network",
    enopkg: "Package not installed",
    enoprotoopt: "Bad protocol option",
    enospc: "No space left on device",
    enosr: "Out of stream resources or not a stream device",
    enosym: "Unresolved symbol name",
    enosys: "Function not implemented",
    enotblk: "Block device required",
    enotconn: "Socket is not connected",
    enotdir: "Not a directory",
    enotempty: "Directory not empty",
    enotnam: "Not a named file",
    enotsock: "Socket operation on non-socket",
    enotsup: "Operation not supported",
    enotty: "Inappropriate device for ioctl",
    enotuniq: "Name not unique on network",
    enxio: "No such device or address",
    eopnotsupp: "Operation not supported on socket",
    eperm: "Not owner",
    epfnosupport: "Protocol family not supported",
    epipe: "Broken pipe",
    eproclim: "Too many processes",
    eprocunavail: "Bad procedure for program",
    eprogmismatch: "Wrong program version",
    eprogunavail: "RPC program unavailable",
    eproto: "Protocol error",
    eprotonosupport: "Protocol not supported",
    eprototype: "Wrong protocol type for socket",
    erange: "Math result unrepresentable",
    erefused: "EREFUSED",
    eremchg: "Remote address changed",
    eremdev: "Remote device",
    eremote: "Pathname hit remote filesystem",
    eremoteio: "Remote I/O error",
    eremoterelease: "EREMOTERELEASE",
    erofs: "Read-only filesystem",
    erpcmismatch: "Wrong RPC version",
    erremote: "Object is remote",
    eshutdown: "Cannot send after socket shutdown",
    esocktnosupport: "Socket type not supported",
    espipe: "Invalid seek",
    esrch: "No such process",
    esrmnt: "Srmount error",
    estale: "Stale remote file handle",
    esuccess: "Error 0",
    etime: "Timer expired",
    etimedout: "Connection timed out",
    etoomanyrefs: "Too many references",
    etxtbsy: "Text file or pseudo-device busy",
    euclean: "Structure needs cleaning",
    eunatch: "Protocol driver not attached",
    eusers: "Too many users",
    eversion: "Version mismatch",
    ewouldblock: "Operation would block",
    exdev: "Cross-domain link",
    exfull: "Message tables full",
    nxdomain: "Hostname or domain name cannot be found"
  ]

  @impl Mechanizex.HTTPAdapter
  @spec request(pid(), Request.t()) :: {atom(), Page.t() | Error.t()}
  def request(browser, req) do
    case HTTPoison.request(req.method, req.url, req.body, req.headers, params: req.params) do
      {:ok, res} ->
        {:ok,
         %Page{
           response: %Response{
             body: res.body,
             headers: res.headers,
             code: res.status_code,
             url: req.url
           },
           request: req,
           browser: browser,
           parser: Browser.html_parser(browser)
         }}

      {:error, error} ->
        {:error, %NetworkError{cause: error, message: "#{@posix_errors[error.reason]} (#{error.reason})"}}
    end
  end
end
