
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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
                           "us-east-1": "fsx.us-east-1.amazonaws.com", "cn-northwest-1": "fsx.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "fsx.ap-south-1.amazonaws.com",
                           "eu-north-1": "fsx.eu-north-1.amazonaws.com", "ap-northeast-2": "fsx.ap-northeast-2.amazonaws.com",
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
      "ap-south-1": "fsx.ap-south-1.amazonaws.com",
      "eu-north-1": "fsx.eu-north-1.amazonaws.com",
      "ap-northeast-2": "fsx.ap-northeast-2.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelDataRepositoryTask_612996 = ref object of OpenApiRestCall_612658
proc url_CancelDataRepositoryTask_612998(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelDataRepositoryTask_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_CancelDataRepositoryTask_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_CancelDataRepositoryTask_612996; body: JsonNode): Recallable =
  ## cancelDataRepositoryTask
  ## <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var cancelDataRepositoryTask* = Call_CancelDataRepositoryTask_612996(
    name: "cancelDataRepositoryTask", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CancelDataRepositoryTask",
    validator: validate_CancelDataRepositoryTask_612997, base: "/",
    url: url_CancelDataRepositoryTask_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackup_613265 = ref object of OpenApiRestCall_612658
proc url_CreateBackup_613267(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBackup_613266(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateBackup"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_CreateBackup_613265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_CreateBackup_613265; body: JsonNode): Recallable =
  ## createBackup
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var createBackup* = Call_CreateBackup_613265(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup",
    validator: validate_CreateBackup_613266, base: "/", url: url_CreateBackup_613267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataRepositoryTask_613280 = ref object of OpenApiRestCall_612658
proc url_CreateDataRepositoryTask_613282(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataRepositoryTask_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repository. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to its linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Using Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/getting-started-step1.html">Step 1: Create Your Amazon FSx for Lustre File System</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CreateDataRepositoryTask_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repository. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to its linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Using Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/getting-started-step1.html">Step 1: Create Your Amazon FSx for Lustre File System</a>.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateDataRepositoryTask_613280; body: JsonNode): Recallable =
  ## createDataRepositoryTask
  ## Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repository. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to its linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Using Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/getting-started-step1.html">Step 1: Create Your Amazon FSx for Lustre File System</a>.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createDataRepositoryTask* = Call_CreateDataRepositoryTask_613280(
    name: "createDataRepositoryTask", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryTask",
    validator: validate_CreateDataRepositoryTask_613281, base: "/",
    url: url_CreateDataRepositoryTask_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystem_613295 = ref object of OpenApiRestCall_612658
proc url_CreateFileSystem_613297(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFileSystem_613296(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateFileSystem"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateFileSystem_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateFileSystem_613295; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createFileSystem* = Call_CreateFileSystem_613295(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem",
    validator: validate_CreateFileSystem_613296, base: "/",
    url: url_CreateFileSystem_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystemFromBackup_613310 = ref object of OpenApiRestCall_612658
proc url_CreateFileSystemFromBackup_613312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFileSystemFromBackup_613311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_CreateFileSystemFromBackup_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateFileSystemFromBackup_613310; body: JsonNode): Recallable =
  ## createFileSystemFromBackup
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createFileSystemFromBackup* = Call_CreateFileSystemFromBackup_613310(
    name: "createFileSystemFromBackup", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup",
    validator: validate_CreateFileSystemFromBackup_613311, base: "/",
    url: url_CreateFileSystemFromBackup_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_613325 = ref object of OpenApiRestCall_612658
proc url_DeleteBackup_613327(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBackup_613326(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DeleteBackup"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_DeleteBackup_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_DeleteBackup_613325; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var deleteBackup* = Call_DeleteBackup_613325(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup",
    validator: validate_DeleteBackup_613326, base: "/", url: url_DeleteBackup_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_613340 = ref object of OpenApiRestCall_612658
proc url_DeleteFileSystem_613342(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFileSystem_613341(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <note> <p>Deleting an Amazon FSx for Lustre file system will fail with a 400 BadRequest if a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state.</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DeleteFileSystem"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DeleteFileSystem_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <note> <p>Deleting an Amazon FSx for Lustre file system will fail with a 400 BadRequest if a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state.</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DeleteFileSystem_613340; body: JsonNode): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <note> <p>Deleting an Amazon FSx for Lustre file system will fail with a 400 BadRequest if a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state.</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var deleteFileSystem* = Call_DeleteFileSystem_613340(name: "deleteFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem",
    validator: validate_DeleteFileSystem_613341, base: "/",
    url: url_DeleteFileSystem_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_613355 = ref object of OpenApiRestCall_612658
proc url_DescribeBackups_613357(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBackups_613356(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613358 = query.getOrDefault("MaxResults")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "MaxResults", valid_613358
  var valid_613359 = query.getOrDefault("NextToken")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "NextToken", valid_613359
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613360 = header.getOrDefault("X-Amz-Target")
  valid_613360 = validateParameter(valid_613360, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeBackups"))
  if valid_613360 != nil:
    section.add "X-Amz-Target", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Signature")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Signature", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Content-Sha256", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Date")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Date", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Credential")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Credential", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Security-Token")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Security-Token", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Algorithm")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Algorithm", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-SignedHeaders", valid_613367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613369: Call_DescribeBackups_613355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_613369.validator(path, query, header, formData, body)
  let scheme = call_613369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613369.url(scheme.get, call_613369.host, call_613369.base,
                         call_613369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613369, url, valid)

proc call*(call_613370: Call_DescribeBackups_613355; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeBackups
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613371 = newJObject()
  var body_613372 = newJObject()
  add(query_613371, "MaxResults", newJString(MaxResults))
  add(query_613371, "NextToken", newJString(NextToken))
  if body != nil:
    body_613372 = body
  result = call_613370.call(nil, query_613371, nil, nil, body_613372)

var describeBackups* = Call_DescribeBackups_613355(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups",
    validator: validate_DescribeBackups_613356, base: "/", url: url_DescribeBackups_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataRepositoryTasks_613374 = ref object of OpenApiRestCall_612658
proc url_DescribeDataRepositoryTasks_613376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDataRepositoryTasks_613375(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the description of specific Amazon FSx for Lustre data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613377 = query.getOrDefault("MaxResults")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "MaxResults", valid_613377
  var valid_613378 = query.getOrDefault("NextToken")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "NextToken", valid_613378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613379 = header.getOrDefault("X-Amz-Target")
  valid_613379 = validateParameter(valid_613379, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks"))
  if valid_613379 != nil:
    section.add "X-Amz-Target", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Signature")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Signature", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Content-Sha256", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Date")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Date", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Credential")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Credential", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Security-Token")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Security-Token", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Algorithm")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Algorithm", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-SignedHeaders", valid_613386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613388: Call_DescribeDataRepositoryTasks_613374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of specific Amazon FSx for Lustre data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
  ## 
  let valid = call_613388.validator(path, query, header, formData, body)
  let scheme = call_613388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613388.url(scheme.get, call_613388.host, call_613388.base,
                         call_613388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613388, url, valid)

proc call*(call_613389: Call_DescribeDataRepositoryTasks_613374; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeDataRepositoryTasks
  ## <p>Returns the description of specific Amazon FSx for Lustre data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613390 = newJObject()
  var body_613391 = newJObject()
  add(query_613390, "MaxResults", newJString(MaxResults))
  add(query_613390, "NextToken", newJString(NextToken))
  if body != nil:
    body_613391 = body
  result = call_613389.call(nil, query_613390, nil, nil, body_613391)

var describeDataRepositoryTasks* = Call_DescribeDataRepositoryTasks_613374(
    name: "describeDataRepositoryTasks", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks",
    validator: validate_DescribeDataRepositoryTasks_613375, base: "/",
    url: url_DescribeDataRepositoryTasks_613376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_613392 = ref object of OpenApiRestCall_612658
proc url_DescribeFileSystems_613394(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFileSystems_613393(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613395 = query.getOrDefault("MaxResults")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "MaxResults", valid_613395
  var valid_613396 = query.getOrDefault("NextToken")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "NextToken", valid_613396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613397 = header.getOrDefault("X-Amz-Target")
  valid_613397 = validateParameter(valid_613397, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeFileSystems"))
  if valid_613397 != nil:
    section.add "X-Amz-Target", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Signature")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Signature", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Content-Sha256", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Date")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Date", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Credential")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Credential", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Security-Token")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Security-Token", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Algorithm")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Algorithm", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-SignedHeaders", valid_613404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613406: Call_DescribeFileSystems_613392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_613406.validator(path, query, header, formData, body)
  let scheme = call_613406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613406.url(scheme.get, call_613406.host, call_613406.base,
                         call_613406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613406, url, valid)

proc call*(call_613407: Call_DescribeFileSystems_613392; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeFileSystems
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613408 = newJObject()
  var body_613409 = newJObject()
  add(query_613408, "MaxResults", newJString(MaxResults))
  add(query_613408, "NextToken", newJString(NextToken))
  if body != nil:
    body_613409 = body
  result = call_613407.call(nil, query_613408, nil, nil, body_613409)

var describeFileSystems* = Call_DescribeFileSystems_613392(
    name: "describeFileSystems", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems",
    validator: validate_DescribeFileSystems_613393, base: "/",
    url: url_DescribeFileSystems_613394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613410 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613412(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_613411(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613413 = header.getOrDefault("X-Amz-Target")
  valid_613413 = validateParameter(valid_613413, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.ListTagsForResource"))
  if valid_613413 != nil:
    section.add "X-Amz-Target", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Signature")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Signature", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Content-Sha256", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Date")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Date", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Credential")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Credential", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Security-Token")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Security-Token", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Algorithm")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Algorithm", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-SignedHeaders", valid_613420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613422: Call_ListTagsForResource_613410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_613422.validator(path, query, header, formData, body)
  let scheme = call_613422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613422.url(scheme.get, call_613422.host, call_613422.base,
                         call_613422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613422, url, valid)

proc call*(call_613423: Call_ListTagsForResource_613410; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613424 = newJObject()
  if body != nil:
    body_613424 = body
  result = call_613423.call(nil, nil, nil, nil, body_613424)

var listTagsForResource* = Call_ListTagsForResource_613410(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource",
    validator: validate_ListTagsForResource_613411, base: "/",
    url: url_ListTagsForResource_613412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613425 = ref object of OpenApiRestCall_612658
proc url_TagResource_613427(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_613426(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Tags an Amazon FSx resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613428 = header.getOrDefault("X-Amz-Target")
  valid_613428 = validateParameter(valid_613428, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.TagResource"))
  if valid_613428 != nil:
    section.add "X-Amz-Target", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Signature")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Signature", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Content-Sha256", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Date")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Date", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Credential")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Credential", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Security-Token")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Security-Token", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Algorithm")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Algorithm", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-SignedHeaders", valid_613435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613437: Call_TagResource_613425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags an Amazon FSx resource.
  ## 
  let valid = call_613437.validator(path, query, header, formData, body)
  let scheme = call_613437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613437.url(scheme.get, call_613437.host, call_613437.base,
                         call_613437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613437, url, valid)

proc call*(call_613438: Call_TagResource_613425; body: JsonNode): Recallable =
  ## tagResource
  ## Tags an Amazon FSx resource.
  ##   body: JObject (required)
  var body_613439 = newJObject()
  if body != nil:
    body_613439 = body
  result = call_613438.call(nil, nil, nil, nil, body_613439)

var tagResource* = Call_TagResource_613425(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource",
                                        validator: validate_TagResource_613426,
                                        base: "/", url: url_TagResource_613427,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613440 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613442(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_613441(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This action removes a tag from an Amazon FSx resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613443 = header.getOrDefault("X-Amz-Target")
  valid_613443 = validateParameter(valid_613443, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.UntagResource"))
  if valid_613443 != nil:
    section.add "X-Amz-Target", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Signature")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Signature", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Content-Sha256", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Date")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Date", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Credential")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Credential", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Security-Token")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Security-Token", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Algorithm")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Algorithm", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-SignedHeaders", valid_613450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_UntagResource_613440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This action removes a tag from an Amazon FSx resource.
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_UntagResource_613440; body: JsonNode): Recallable =
  ## untagResource
  ## This action removes a tag from an Amazon FSx resource.
  ##   body: JObject (required)
  var body_613454 = newJObject()
  if body != nil:
    body_613454 = body
  result = call_613453.call(nil, nil, nil, nil, body_613454)

var untagResource* = Call_UntagResource_613440(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource",
    validator: validate_UntagResource_613441, base: "/", url: url_UntagResource_613442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_613455 = ref object of OpenApiRestCall_612658
proc url_UpdateFileSystem_613457(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFileSystem_613456(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a file system configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613458 = header.getOrDefault("X-Amz-Target")
  valid_613458 = validateParameter(valid_613458, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.UpdateFileSystem"))
  if valid_613458 != nil:
    section.add "X-Amz-Target", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Signature")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Signature", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Content-Sha256", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Date")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Date", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Credential")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Credential", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Security-Token")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Security-Token", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Algorithm")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Algorithm", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-SignedHeaders", valid_613465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613467: Call_UpdateFileSystem_613455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a file system configuration.
  ## 
  let valid = call_613467.validator(path, query, header, formData, body)
  let scheme = call_613467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613467.url(scheme.get, call_613467.host, call_613467.base,
                         call_613467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613467, url, valid)

proc call*(call_613468: Call_UpdateFileSystem_613455; body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates a file system configuration.
  ##   body: JObject (required)
  var body_613469 = newJObject()
  if body != nil:
    body_613469 = body
  result = call_613468.call(nil, nil, nil, nil, body_613469)

var updateFileSystem* = Call_UpdateFileSystem_613455(name: "updateFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem",
    validator: validate_UpdateFileSystem_613456, base: "/",
    url: url_UpdateFileSystem_613457, schemes: {Scheme.Https, Scheme.Http})
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
  let
    algo = SHA256
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
