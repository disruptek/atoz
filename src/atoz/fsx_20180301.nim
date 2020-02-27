
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: Amazon FSx
## version: 2018-03-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon FSx is a fully managed service that makes it easy for storage and application administrators to launch and use shared file storage.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/fsx/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "fsx.ap-northeast-1.amazonaws.com", "ap-southeast-1": "fsx.ap-southeast-1.amazonaws.com",
                           "us-west-2": "fsx.us-west-2.amazonaws.com",
                           "eu-west-2": "fsx.eu-west-2.amazonaws.com", "ap-northeast-3": "fsx.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "fsx.eu-central-1.amazonaws.com",
                           "us-east-2": "fsx.us-east-2.amazonaws.com",
                           "us-east-1": "fsx.us-east-1.amazonaws.com", "cn-northwest-1": "fsx.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "fsx.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "fsx.ap-south-1.amazonaws.com",
                           "eu-north-1": "fsx.eu-north-1.amazonaws.com",
                           "us-west-1": "fsx.us-west-1.amazonaws.com",
                           "us-gov-east-1": "fsx.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "fsx.eu-west-3.amazonaws.com",
                           "cn-north-1": "fsx.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "fsx.sa-east-1.amazonaws.com",
                           "eu-west-1": "fsx.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "fsx.us-gov-west-1.amazonaws.com", "ap-southeast-2": "fsx.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "fsx.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "fsx.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "fsx.ap-southeast-1.amazonaws.com",
      "us-west-2": "fsx.us-west-2.amazonaws.com",
      "eu-west-2": "fsx.eu-west-2.amazonaws.com",
      "ap-northeast-3": "fsx.ap-northeast-3.amazonaws.com",
      "eu-central-1": "fsx.eu-central-1.amazonaws.com",
      "us-east-2": "fsx.us-east-2.amazonaws.com",
      "us-east-1": "fsx.us-east-1.amazonaws.com",
      "cn-northwest-1": "fsx.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "fsx.ap-northeast-2.amazonaws.com",
      "ap-south-1": "fsx.ap-south-1.amazonaws.com",
      "eu-north-1": "fsx.eu-north-1.amazonaws.com",
      "us-west-1": "fsx.us-west-1.amazonaws.com",
      "us-gov-east-1": "fsx.us-gov-east-1.amazonaws.com",
      "eu-west-3": "fsx.eu-west-3.amazonaws.com",
      "cn-north-1": "fsx.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "fsx.sa-east-1.amazonaws.com",
      "eu-west-1": "fsx.eu-west-1.amazonaws.com",
      "us-gov-west-1": "fsx.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "fsx.ap-southeast-2.amazonaws.com",
      "ca-central-1": "fsx.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "fsx"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CancelDataRepositoryTask_617205 = ref object of OpenApiRestCall_616866
proc url_CancelDataRepositoryTask_617207(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelDataRepositoryTask_617206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617319 = header.getOrDefault("X-Amz-Date")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "X-Amz-Date", valid_617319
  var valid_617320 = header.getOrDefault("X-Amz-Security-Token")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Security-Token", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Content-Sha256", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Algorithm")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Algorithm", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Signature")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Signature", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-SignedHeaders", valid_617324
  var valid_617338 = header.getOrDefault("X-Amz-Target")
  valid_617338 = validateParameter(valid_617338, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"))
  if valid_617338 != nil:
    section.add "X-Amz-Target", valid_617338
  var valid_617339 = header.getOrDefault("X-Amz-Credential")
  valid_617339 = validateParameter(valid_617339, JString, required = false,
                                 default = nil)
  if valid_617339 != nil:
    section.add "X-Amz-Credential", valid_617339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617364: Call_CancelDataRepositoryTask_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
  ## 
  let valid = call_617364.validator(path, query, header, formData, body, _)
  let scheme = call_617364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617364.url(scheme.get, call_617364.host, call_617364.base,
                         call_617364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617364, url, valid, _)

proc call*(call_617435: Call_CancelDataRepositoryTask_617205; body: JsonNode): Recallable =
  ## cancelDataRepositoryTask
  ## <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617436 = newJObject()
  if body != nil:
    body_617436 = body
  result = call_617435.call(nil, nil, nil, nil, body_617436)

var cancelDataRepositoryTask* = Call_CancelDataRepositoryTask_617205(
    name: "cancelDataRepositoryTask", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CancelDataRepositoryTask",
    validator: validate_CancelDataRepositoryTask_617206, base: "/",
    url: url_CancelDataRepositoryTask_617207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_617477 = ref object of OpenApiRestCall_616866
proc url_CreateBackup_617479(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackup_617478(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617480 = header.getOrDefault("X-Amz-Date")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Date", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Security-Token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Security-Token", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Content-Sha256", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Algorithm")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Algorithm", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Signature")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Signature", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-SignedHeaders", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Target")
  valid_617486 = validateParameter(valid_617486, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateBackup"))
  if valid_617486 != nil:
    section.add "X-Amz-Target", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Credential")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Credential", valid_617487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617489: Call_CreateBackup_617477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ## 
  let valid = call_617489.validator(path, query, header, formData, body, _)
  let scheme = call_617489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617489.url(scheme.get, call_617489.host, call_617489.base,
                         call_617489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617489, url, valid, _)

proc call*(call_617490: Call_CreateBackup_617477; body: JsonNode): Recallable =
  ## createBackup
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ##   body: JObject (required)
  var body_617491 = newJObject()
  if body != nil:
    body_617491 = body
  result = call_617490.call(nil, nil, nil, nil, body_617491)

var createBackup* = Call_CreateBackup_617477(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup",
    validator: validate_CreateBackup_617478, base: "/", url: url_CreateBackup_617479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataRepositoryTask_617492 = ref object of OpenApiRestCall_616866
proc url_CreateDataRepositoryTask_617494(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataRepositoryTask_617493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repository. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to its linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Using Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/getting-started-step1.html">Step 1: Create Your Amazon FSx for Lustre File System</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617495 = header.getOrDefault("X-Amz-Date")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Date", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Security-Token")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Security-Token", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Content-Sha256", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Algorithm")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Algorithm", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Signature")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Signature", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-SignedHeaders", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Target")
  valid_617501 = validateParameter(valid_617501, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"))
  if valid_617501 != nil:
    section.add "X-Amz-Target", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Credential")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Credential", valid_617502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617504: Call_CreateDataRepositoryTask_617492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repository. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to its linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Using Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/getting-started-step1.html">Step 1: Create Your Amazon FSx for Lustre File System</a>.
  ## 
  let valid = call_617504.validator(path, query, header, formData, body, _)
  let scheme = call_617504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617504.url(scheme.get, call_617504.host, call_617504.base,
                         call_617504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617504, url, valid, _)

proc call*(call_617505: Call_CreateDataRepositoryTask_617492; body: JsonNode): Recallable =
  ## createDataRepositoryTask
  ## Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repository. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to its linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Using Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/getting-started-step1.html">Step 1: Create Your Amazon FSx for Lustre File System</a>.
  ##   body: JObject (required)
  var body_617506 = newJObject()
  if body != nil:
    body_617506 = body
  result = call_617505.call(nil, nil, nil, nil, body_617506)

var createDataRepositoryTask* = Call_CreateDataRepositoryTask_617492(
    name: "createDataRepositoryTask", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryTask",
    validator: validate_CreateDataRepositoryTask_617493, base: "/",
    url: url_CreateDataRepositoryTask_617494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystem_617507 = ref object of OpenApiRestCall_616866
proc url_CreateFileSystem_617509(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFileSystem_617508(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617510 = header.getOrDefault("X-Amz-Date")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-Date", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Security-Token")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Security-Token", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Content-Sha256", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-Algorithm")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-Algorithm", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Signature")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Signature", valid_617514
  var valid_617515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-SignedHeaders", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-Target")
  valid_617516 = validateParameter(valid_617516, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateFileSystem"))
  if valid_617516 != nil:
    section.add "X-Amz-Target", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Credential")
  valid_617517 = validateParameter(valid_617517, JString, required = false,
                                 default = nil)
  if valid_617517 != nil:
    section.add "X-Amz-Credential", valid_617517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617519: Call_CreateFileSystem_617507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  let valid = call_617519.validator(path, query, header, formData, body, _)
  let scheme = call_617519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617519.url(scheme.get, call_617519.host, call_617519.base,
                         call_617519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617519, url, valid, _)

proc call*(call_617520: Call_CreateFileSystem_617507; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ##   body: JObject (required)
  var body_617521 = newJObject()
  if body != nil:
    body_617521 = body
  result = call_617520.call(nil, nil, nil, nil, body_617521)

var createFileSystem* = Call_CreateFileSystem_617507(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem",
    validator: validate_CreateFileSystem_617508, base: "/",
    url: url_CreateFileSystem_617509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystemFromBackup_617522 = ref object of OpenApiRestCall_616866
proc url_CreateFileSystemFromBackup_617524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFileSystemFromBackup_617523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617525 = header.getOrDefault("X-Amz-Date")
  valid_617525 = validateParameter(valid_617525, JString, required = false,
                                 default = nil)
  if valid_617525 != nil:
    section.add "X-Amz-Date", valid_617525
  var valid_617526 = header.getOrDefault("X-Amz-Security-Token")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Security-Token", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Content-Sha256", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Algorithm")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Algorithm", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Signature")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Signature", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-SignedHeaders", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Target")
  valid_617531 = validateParameter(valid_617531, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"))
  if valid_617531 != nil:
    section.add "X-Amz-Target", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Credential")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Credential", valid_617532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617534: Call_CreateFileSystemFromBackup_617522;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  let valid = call_617534.validator(path, query, header, formData, body, _)
  let scheme = call_617534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617534.url(scheme.get, call_617534.host, call_617534.base,
                         call_617534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617534, url, valid, _)

proc call*(call_617535: Call_CreateFileSystemFromBackup_617522; body: JsonNode): Recallable =
  ## createFileSystemFromBackup
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ##   body: JObject (required)
  var body_617536 = newJObject()
  if body != nil:
    body_617536 = body
  result = call_617535.call(nil, nil, nil, nil, body_617536)

var createFileSystemFromBackup* = Call_CreateFileSystemFromBackup_617522(
    name: "createFileSystemFromBackup", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup",
    validator: validate_CreateFileSystemFromBackup_617523, base: "/",
    url: url_CreateFileSystemFromBackup_617524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_617537 = ref object of OpenApiRestCall_616866
proc url_DeleteBackup_617539(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBackup_617538(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617540 = header.getOrDefault("X-Amz-Date")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Date", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-Security-Token")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-Security-Token", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Content-Sha256", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Algorithm")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Algorithm", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Signature")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Signature", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-SignedHeaders", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Target")
  valid_617546 = validateParameter(valid_617546, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DeleteBackup"))
  if valid_617546 != nil:
    section.add "X-Amz-Target", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Credential")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Credential", valid_617547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617549: Call_DeleteBackup_617537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ## 
  let valid = call_617549.validator(path, query, header, formData, body, _)
  let scheme = call_617549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617549.url(scheme.get, call_617549.host, call_617549.base,
                         call_617549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617549, url, valid, _)

proc call*(call_617550: Call_DeleteBackup_617537; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ##   body: JObject (required)
  var body_617551 = newJObject()
  if body != nil:
    body_617551 = body
  result = call_617550.call(nil, nil, nil, nil, body_617551)

var deleteBackup* = Call_DeleteBackup_617537(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup",
    validator: validate_DeleteBackup_617538, base: "/", url: url_DeleteBackup_617539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_617552 = ref object of OpenApiRestCall_616866
proc url_DeleteFileSystem_617554(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFileSystem_617553(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <note> <p>Deleting an Amazon FSx for Lustre file system will fail with a 400 BadRequest if a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state.</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617555 = header.getOrDefault("X-Amz-Date")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-Date", valid_617555
  var valid_617556 = header.getOrDefault("X-Amz-Security-Token")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-Security-Token", valid_617556
  var valid_617557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Content-Sha256", valid_617557
  var valid_617558 = header.getOrDefault("X-Amz-Algorithm")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Algorithm", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Signature")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Signature", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-SignedHeaders", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-Target")
  valid_617561 = validateParameter(valid_617561, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DeleteFileSystem"))
  if valid_617561 != nil:
    section.add "X-Amz-Target", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-Credential")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-Credential", valid_617562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617564: Call_DeleteFileSystem_617552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <note> <p>Deleting an Amazon FSx for Lustre file system will fail with a 400 BadRequest if a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state.</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ## 
  let valid = call_617564.validator(path, query, header, formData, body, _)
  let scheme = call_617564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617564.url(scheme.get, call_617564.host, call_617564.base,
                         call_617564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617564, url, valid, _)

proc call*(call_617565: Call_DeleteFileSystem_617552; body: JsonNode): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <note> <p>Deleting an Amazon FSx for Lustre file system will fail with a 400 BadRequest if a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state.</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ##   body: JObject (required)
  var body_617566 = newJObject()
  if body != nil:
    body_617566 = body
  result = call_617565.call(nil, nil, nil, nil, body_617566)

var deleteFileSystem* = Call_DeleteFileSystem_617552(name: "deleteFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem",
    validator: validate_DeleteFileSystem_617553, base: "/",
    url: url_DeleteFileSystem_617554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_617567 = ref object of OpenApiRestCall_616866
proc url_DescribeBackups_617569(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBackups_617568(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617570 = query.getOrDefault("NextToken")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "NextToken", valid_617570
  var valid_617571 = query.getOrDefault("MaxResults")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "MaxResults", valid_617571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617572 = header.getOrDefault("X-Amz-Date")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Date", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Security-Token")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Security-Token", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Content-Sha256", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Algorithm")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Algorithm", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Signature")
  valid_617576 = validateParameter(valid_617576, JString, required = false,
                                 default = nil)
  if valid_617576 != nil:
    section.add "X-Amz-Signature", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-SignedHeaders", valid_617577
  var valid_617578 = header.getOrDefault("X-Amz-Target")
  valid_617578 = validateParameter(valid_617578, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeBackups"))
  if valid_617578 != nil:
    section.add "X-Amz-Target", valid_617578
  var valid_617579 = header.getOrDefault("X-Amz-Credential")
  valid_617579 = validateParameter(valid_617579, JString, required = false,
                                 default = nil)
  if valid_617579 != nil:
    section.add "X-Amz-Credential", valid_617579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617581: Call_DescribeBackups_617567; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_617581.validator(path, query, header, formData, body, _)
  let scheme = call_617581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617581.url(scheme.get, call_617581.host, call_617581.base,
                         call_617581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617581, url, valid, _)

proc call*(call_617582: Call_DescribeBackups_617567; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeBackups
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617583 = newJObject()
  var body_617584 = newJObject()
  add(query_617583, "NextToken", newJString(NextToken))
  if body != nil:
    body_617584 = body
  add(query_617583, "MaxResults", newJString(MaxResults))
  result = call_617582.call(nil, query_617583, nil, nil, body_617584)

var describeBackups* = Call_DescribeBackups_617567(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups",
    validator: validate_DescribeBackups_617568, base: "/", url: url_DescribeBackups_617569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataRepositoryTasks_617586 = ref object of OpenApiRestCall_616866
proc url_DescribeDataRepositoryTasks_617588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDataRepositoryTasks_617587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns the description of specific Amazon FSx for Lustre data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617589 = query.getOrDefault("NextToken")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "NextToken", valid_617589
  var valid_617590 = query.getOrDefault("MaxResults")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "MaxResults", valid_617590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617591 = header.getOrDefault("X-Amz-Date")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "X-Amz-Date", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Security-Token")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Security-Token", valid_617592
  var valid_617593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617593 = validateParameter(valid_617593, JString, required = false,
                                 default = nil)
  if valid_617593 != nil:
    section.add "X-Amz-Content-Sha256", valid_617593
  var valid_617594 = header.getOrDefault("X-Amz-Algorithm")
  valid_617594 = validateParameter(valid_617594, JString, required = false,
                                 default = nil)
  if valid_617594 != nil:
    section.add "X-Amz-Algorithm", valid_617594
  var valid_617595 = header.getOrDefault("X-Amz-Signature")
  valid_617595 = validateParameter(valid_617595, JString, required = false,
                                 default = nil)
  if valid_617595 != nil:
    section.add "X-Amz-Signature", valid_617595
  var valid_617596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617596 = validateParameter(valid_617596, JString, required = false,
                                 default = nil)
  if valid_617596 != nil:
    section.add "X-Amz-SignedHeaders", valid_617596
  var valid_617597 = header.getOrDefault("X-Amz-Target")
  valid_617597 = validateParameter(valid_617597, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks"))
  if valid_617597 != nil:
    section.add "X-Amz-Target", valid_617597
  var valid_617598 = header.getOrDefault("X-Amz-Credential")
  valid_617598 = validateParameter(valid_617598, JString, required = false,
                                 default = nil)
  if valid_617598 != nil:
    section.add "X-Amz-Credential", valid_617598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617600: Call_DescribeDataRepositoryTasks_617586;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the description of specific Amazon FSx for Lustre data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
  ## 
  let valid = call_617600.validator(path, query, header, formData, body, _)
  let scheme = call_617600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617600.url(scheme.get, call_617600.host, call_617600.base,
                         call_617600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617600, url, valid, _)

proc call*(call_617601: Call_DescribeDataRepositoryTasks_617586; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeDataRepositoryTasks
  ## <p>Returns the description of specific Amazon FSx for Lustre data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617602 = newJObject()
  var body_617603 = newJObject()
  add(query_617602, "NextToken", newJString(NextToken))
  if body != nil:
    body_617603 = body
  add(query_617602, "MaxResults", newJString(MaxResults))
  result = call_617601.call(nil, query_617602, nil, nil, body_617603)

var describeDataRepositoryTasks* = Call_DescribeDataRepositoryTasks_617586(
    name: "describeDataRepositoryTasks", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks",
    validator: validate_DescribeDataRepositoryTasks_617587, base: "/",
    url: url_DescribeDataRepositoryTasks_617588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_617604 = ref object of OpenApiRestCall_616866
proc url_DescribeFileSystems_617606(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFileSystems_617605(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617607 = query.getOrDefault("NextToken")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "NextToken", valid_617607
  var valid_617608 = query.getOrDefault("MaxResults")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "MaxResults", valid_617608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617609 = header.getOrDefault("X-Amz-Date")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "X-Amz-Date", valid_617609
  var valid_617610 = header.getOrDefault("X-Amz-Security-Token")
  valid_617610 = validateParameter(valid_617610, JString, required = false,
                                 default = nil)
  if valid_617610 != nil:
    section.add "X-Amz-Security-Token", valid_617610
  var valid_617611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617611 = validateParameter(valid_617611, JString, required = false,
                                 default = nil)
  if valid_617611 != nil:
    section.add "X-Amz-Content-Sha256", valid_617611
  var valid_617612 = header.getOrDefault("X-Amz-Algorithm")
  valid_617612 = validateParameter(valid_617612, JString, required = false,
                                 default = nil)
  if valid_617612 != nil:
    section.add "X-Amz-Algorithm", valid_617612
  var valid_617613 = header.getOrDefault("X-Amz-Signature")
  valid_617613 = validateParameter(valid_617613, JString, required = false,
                                 default = nil)
  if valid_617613 != nil:
    section.add "X-Amz-Signature", valid_617613
  var valid_617614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617614 = validateParameter(valid_617614, JString, required = false,
                                 default = nil)
  if valid_617614 != nil:
    section.add "X-Amz-SignedHeaders", valid_617614
  var valid_617615 = header.getOrDefault("X-Amz-Target")
  valid_617615 = validateParameter(valid_617615, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeFileSystems"))
  if valid_617615 != nil:
    section.add "X-Amz-Target", valid_617615
  var valid_617616 = header.getOrDefault("X-Amz-Credential")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "X-Amz-Credential", valid_617616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617618: Call_DescribeFileSystems_617604; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_617618.validator(path, query, header, formData, body, _)
  let scheme = call_617618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617618.url(scheme.get, call_617618.host, call_617618.base,
                         call_617618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617618, url, valid, _)

proc call*(call_617619: Call_DescribeFileSystems_617604; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeFileSystems
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617620 = newJObject()
  var body_617621 = newJObject()
  add(query_617620, "NextToken", newJString(NextToken))
  if body != nil:
    body_617621 = body
  add(query_617620, "MaxResults", newJString(MaxResults))
  result = call_617619.call(nil, query_617620, nil, nil, body_617621)

var describeFileSystems* = Call_DescribeFileSystems_617604(
    name: "describeFileSystems", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems",
    validator: validate_DescribeFileSystems_617605, base: "/",
    url: url_DescribeFileSystems_617606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617622 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617624(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_617623(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617625 = header.getOrDefault("X-Amz-Date")
  valid_617625 = validateParameter(valid_617625, JString, required = false,
                                 default = nil)
  if valid_617625 != nil:
    section.add "X-Amz-Date", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-Security-Token")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Security-Token", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-Content-Sha256", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Algorithm")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Algorithm", valid_617628
  var valid_617629 = header.getOrDefault("X-Amz-Signature")
  valid_617629 = validateParameter(valid_617629, JString, required = false,
                                 default = nil)
  if valid_617629 != nil:
    section.add "X-Amz-Signature", valid_617629
  var valid_617630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-SignedHeaders", valid_617630
  var valid_617631 = header.getOrDefault("X-Amz-Target")
  valid_617631 = validateParameter(valid_617631, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.ListTagsForResource"))
  if valid_617631 != nil:
    section.add "X-Amz-Target", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-Credential")
  valid_617632 = validateParameter(valid_617632, JString, required = false,
                                 default = nil)
  if valid_617632 != nil:
    section.add "X-Amz-Credential", valid_617632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617634: Call_ListTagsForResource_617622; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_617634.validator(path, query, header, formData, body, _)
  let scheme = call_617634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617634.url(scheme.get, call_617634.host, call_617634.base,
                         call_617634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617634, url, valid, _)

proc call*(call_617635: Call_ListTagsForResource_617622; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617636 = newJObject()
  if body != nil:
    body_617636 = body
  result = call_617635.call(nil, nil, nil, nil, body_617636)

var listTagsForResource* = Call_ListTagsForResource_617622(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource",
    validator: validate_ListTagsForResource_617623, base: "/",
    url: url_ListTagsForResource_617624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617637 = ref object of OpenApiRestCall_616866
proc url_TagResource_617639(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617638(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Tags an Amazon FSx resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617640 = header.getOrDefault("X-Amz-Date")
  valid_617640 = validateParameter(valid_617640, JString, required = false,
                                 default = nil)
  if valid_617640 != nil:
    section.add "X-Amz-Date", valid_617640
  var valid_617641 = header.getOrDefault("X-Amz-Security-Token")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Security-Token", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Content-Sha256", valid_617642
  var valid_617643 = header.getOrDefault("X-Amz-Algorithm")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "X-Amz-Algorithm", valid_617643
  var valid_617644 = header.getOrDefault("X-Amz-Signature")
  valid_617644 = validateParameter(valid_617644, JString, required = false,
                                 default = nil)
  if valid_617644 != nil:
    section.add "X-Amz-Signature", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-SignedHeaders", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-Target")
  valid_617646 = validateParameter(valid_617646, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.TagResource"))
  if valid_617646 != nil:
    section.add "X-Amz-Target", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Credential")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "X-Amz-Credential", valid_617647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617649: Call_TagResource_617637; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tags an Amazon FSx resource.
  ## 
  let valid = call_617649.validator(path, query, header, formData, body, _)
  let scheme = call_617649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617649.url(scheme.get, call_617649.host, call_617649.base,
                         call_617649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617649, url, valid, _)

proc call*(call_617650: Call_TagResource_617637; body: JsonNode): Recallable =
  ## tagResource
  ## Tags an Amazon FSx resource.
  ##   body: JObject (required)
  var body_617651 = newJObject()
  if body != nil:
    body_617651 = body
  result = call_617650.call(nil, nil, nil, nil, body_617651)

var tagResource* = Call_TagResource_617637(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource",
                                        validator: validate_TagResource_617638,
                                        base: "/", url: url_TagResource_617639,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617652 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617654(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617653(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## This action removes a tag from an Amazon FSx resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617655 = header.getOrDefault("X-Amz-Date")
  valid_617655 = validateParameter(valid_617655, JString, required = false,
                                 default = nil)
  if valid_617655 != nil:
    section.add "X-Amz-Date", valid_617655
  var valid_617656 = header.getOrDefault("X-Amz-Security-Token")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "X-Amz-Security-Token", valid_617656
  var valid_617657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617657 = validateParameter(valid_617657, JString, required = false,
                                 default = nil)
  if valid_617657 != nil:
    section.add "X-Amz-Content-Sha256", valid_617657
  var valid_617658 = header.getOrDefault("X-Amz-Algorithm")
  valid_617658 = validateParameter(valid_617658, JString, required = false,
                                 default = nil)
  if valid_617658 != nil:
    section.add "X-Amz-Algorithm", valid_617658
  var valid_617659 = header.getOrDefault("X-Amz-Signature")
  valid_617659 = validateParameter(valid_617659, JString, required = false,
                                 default = nil)
  if valid_617659 != nil:
    section.add "X-Amz-Signature", valid_617659
  var valid_617660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-SignedHeaders", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Target")
  valid_617661 = validateParameter(valid_617661, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.UntagResource"))
  if valid_617661 != nil:
    section.add "X-Amz-Target", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Credential")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-Credential", valid_617662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617664: Call_UntagResource_617652; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This action removes a tag from an Amazon FSx resource.
  ## 
  let valid = call_617664.validator(path, query, header, formData, body, _)
  let scheme = call_617664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617664.url(scheme.get, call_617664.host, call_617664.base,
                         call_617664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617664, url, valid, _)

proc call*(call_617665: Call_UntagResource_617652; body: JsonNode): Recallable =
  ## untagResource
  ## This action removes a tag from an Amazon FSx resource.
  ##   body: JObject (required)
  var body_617666 = newJObject()
  if body != nil:
    body_617666 = body
  result = call_617665.call(nil, nil, nil, nil, body_617666)

var untagResource* = Call_UntagResource_617652(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource",
    validator: validate_UntagResource_617653, base: "/", url: url_UntagResource_617654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_617667 = ref object of OpenApiRestCall_616866
proc url_UpdateFileSystem_617669(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFileSystem_617668(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## Updates a file system configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617670 = header.getOrDefault("X-Amz-Date")
  valid_617670 = validateParameter(valid_617670, JString, required = false,
                                 default = nil)
  if valid_617670 != nil:
    section.add "X-Amz-Date", valid_617670
  var valid_617671 = header.getOrDefault("X-Amz-Security-Token")
  valid_617671 = validateParameter(valid_617671, JString, required = false,
                                 default = nil)
  if valid_617671 != nil:
    section.add "X-Amz-Security-Token", valid_617671
  var valid_617672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617672 = validateParameter(valid_617672, JString, required = false,
                                 default = nil)
  if valid_617672 != nil:
    section.add "X-Amz-Content-Sha256", valid_617672
  var valid_617673 = header.getOrDefault("X-Amz-Algorithm")
  valid_617673 = validateParameter(valid_617673, JString, required = false,
                                 default = nil)
  if valid_617673 != nil:
    section.add "X-Amz-Algorithm", valid_617673
  var valid_617674 = header.getOrDefault("X-Amz-Signature")
  valid_617674 = validateParameter(valid_617674, JString, required = false,
                                 default = nil)
  if valid_617674 != nil:
    section.add "X-Amz-Signature", valid_617674
  var valid_617675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-SignedHeaders", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-Target")
  valid_617676 = validateParameter(valid_617676, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.UpdateFileSystem"))
  if valid_617676 != nil:
    section.add "X-Amz-Target", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Credential")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Credential", valid_617677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617679: Call_UpdateFileSystem_617667; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a file system configuration.
  ## 
  let valid = call_617679.validator(path, query, header, formData, body, _)
  let scheme = call_617679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617679.url(scheme.get, call_617679.host, call_617679.base,
                         call_617679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617679, url, valid, _)

proc call*(call_617680: Call_UpdateFileSystem_617667; body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates a file system configuration.
  ##   body: JObject (required)
  var body_617681 = newJObject()
  if body != nil:
    body_617681 = body
  result = call_617680.call(nil, nil, nil, nil, body_617681)

var updateFileSystem* = Call_UpdateFileSystem_617667(name: "updateFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem",
    validator: validate_UpdateFileSystem_617668, base: "/",
    url: url_UpdateFileSystem_617669, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
