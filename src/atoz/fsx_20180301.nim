
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateBackup_600768 = ref object of OpenApiRestCall_600426
proc url_CreateBackup_600770(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateBackup_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateBackup"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_CreateBackup_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_CreateBackup_600768; body: JsonNode): Recallable =
  ## createBackup
  ## <p>Creates a backup of an existing Amazon FSx for Windows File Server file system. Creating regular backups for your file system is a best practice that complements the replication that Amazon FSx for Windows File Server performs for your file system. It also enables you to restore from user modification of data.</p> <p>If a backup with the specified client request token exists, and the parameters match, this operation returns the description of the existing backup. If a backup specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateFileSystem</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the file system creation status by calling the <a>DescribeBackups</a> operation, which returns the backup state along with other information.</p> <note> <p/> </note>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var createBackup* = Call_CreateBackup_600768(name: "createBackup",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup",
    validator: validate_CreateBackup_600769, base: "/", url: url_CreateBackup_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystem_601037 = ref object of OpenApiRestCall_600426
proc url_CreateFileSystem_601039(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFileSystem_601038(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateFileSystem"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_CreateFileSystem_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_CreateFileSystem_601037; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty Amazon FSx file system.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var createFileSystem* = Call_CreateFileSystem_601037(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem",
    validator: validate_CreateFileSystem_601038, base: "/",
    url: url_CreateFileSystem_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystemFromBackup_601052 = ref object of OpenApiRestCall_600426
proc url_CreateFileSystemFromBackup_601054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFileSystemFromBackup_601053(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateFileSystemFromBackup_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateFileSystemFromBackup_601052; body: JsonNode): Recallable =
  ## createFileSystemFromBackup
  ## <p>Creates a new Amazon FSx file system from an existing Amazon FSx for Windows File Server backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a client request token specified by the file system exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a>DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createFileSystemFromBackup* = Call_CreateFileSystemFromBackup_601052(
    name: "createFileSystemFromBackup", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup",
    validator: validate_CreateFileSystemFromBackup_601053, base: "/",
    url: url_CreateFileSystemFromBackup_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackup_601067 = ref object of OpenApiRestCall_600426
proc url_DeleteBackup_601069(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteBackup_601068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DeleteBackup"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_DeleteBackup_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_DeleteBackup_601067; body: JsonNode): Recallable =
  ## deleteBackup
  ## <p>Deletes an Amazon FSx for Windows File Server backup, deleting its contents. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup will not show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var deleteBackup* = Call_DeleteBackup_601067(name: "deleteBackup",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup",
    validator: validate_DeleteBackup_601068, base: "/", url: url_DeleteBackup_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_601082 = ref object of OpenApiRestCall_600426
proc url_DeleteFileSystem_601084(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFileSystem_601083(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DeleteFileSystem"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DeleteFileSystem_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DeleteFileSystem_601082; body: JsonNode): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, deleting its contents. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups will also be deleted.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup is not subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> action returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> action, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <a>DescribeFileSystems</a> returns a <code>FileSystemNotFound</code> error.</p> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var deleteFileSystem* = Call_DeleteFileSystem_601082(name: "deleteFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem",
    validator: validate_DeleteFileSystem_601083, base: "/",
    url: url_DeleteFileSystem_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackups_601097 = ref object of OpenApiRestCall_600426
proc url_DescribeBackups_601099(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeBackups_601098(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_601100 = query.getOrDefault("NextToken")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "NextToken", valid_601100
  var valid_601101 = query.getOrDefault("MaxResults")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "MaxResults", valid_601101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601104 = header.getOrDefault("X-Amz-Target")
  valid_601104 = validateParameter(valid_601104, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeBackups"))
  if valid_601104 != nil:
    section.add "X-Amz-Target", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Content-Sha256", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Algorithm")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Algorithm", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Signature")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Signature", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-SignedHeaders", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Credential")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Credential", valid_601109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_DescribeBackups_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"))
  result = hook(call_601111, url, valid)

proc call*(call_601112: Call_DescribeBackups_601097; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeBackups
  ## <p>Returns the description of specific Amazon FSx for Windows File Server backups, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of backups returned in the response of one <code>DescribeBackups</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601113 = newJObject()
  var body_601114 = newJObject()
  add(query_601113, "NextToken", newJString(NextToken))
  if body != nil:
    body_601114 = body
  add(query_601113, "MaxResults", newJString(MaxResults))
  result = call_601112.call(nil, query_601113, nil, nil, body_601114)

var describeBackups* = Call_DescribeBackups_601097(name: "describeBackups",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups",
    validator: validate_DescribeBackups_601098, base: "/", url: url_DescribeBackups_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_601116 = ref object of OpenApiRestCall_600426
proc url_DescribeFileSystems_601118(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFileSystems_601117(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_601119 = query.getOrDefault("NextToken")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "NextToken", valid_601119
  var valid_601120 = query.getOrDefault("MaxResults")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "MaxResults", valid_601120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.DescribeFileSystems"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_DescribeFileSystems_601116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_DescribeFileSystems_601116; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeFileSystems
  ## <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601132 = newJObject()
  var body_601133 = newJObject()
  add(query_601132, "NextToken", newJString(NextToken))
  if body != nil:
    body_601133 = body
  add(query_601132, "MaxResults", newJString(MaxResults))
  result = call_601131.call(nil, query_601132, nil, nil, body_601133)

var describeFileSystems* = Call_DescribeFileSystems_601116(
    name: "describeFileSystems", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems",
    validator: validate_DescribeFileSystems_601117, base: "/",
    url: url_DescribeFileSystems_601118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601134 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601136(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601135(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601139 = header.getOrDefault("X-Amz-Target")
  valid_601139 = validateParameter(valid_601139, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.ListTagsForResource"))
  if valid_601139 != nil:
    section.add "X-Amz-Target", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Content-Sha256", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Algorithm")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Algorithm", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Signature")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Signature", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-SignedHeaders", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Credential")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Credential", valid_601144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_ListTagsForResource_601134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_ListTagsForResource_601134; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for an Amazon FSx file systems and backups in the case of Amazon FSx for Windows File Server.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601148 = newJObject()
  if body != nil:
    body_601148 = body
  result = call_601147.call(nil, nil, nil, nil, body_601148)

var listTagsForResource* = Call_ListTagsForResource_601134(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource",
    validator: validate_ListTagsForResource_601135, base: "/",
    url: url_ListTagsForResource_601136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601149 = ref object of OpenApiRestCall_600426
proc url_TagResource_601151(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601150(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601154 = header.getOrDefault("X-Amz-Target")
  valid_601154 = validateParameter(valid_601154, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.TagResource"))
  if valid_601154 != nil:
    section.add "X-Amz-Target", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Content-Sha256", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Algorithm")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Algorithm", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Signature")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Signature", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-SignedHeaders", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Credential")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Credential", valid_601159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_TagResource_601149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags an Amazon FSx resource.
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_TagResource_601149; body: JsonNode): Recallable =
  ## tagResource
  ## Tags an Amazon FSx resource.
  ##   body: JObject (required)
  var body_601163 = newJObject()
  if body != nil:
    body_601163 = body
  result = call_601162.call(nil, nil, nil, nil, body_601163)

var tagResource* = Call_TagResource_601149(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "fsx.amazonaws.com", route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource",
                                        validator: validate_TagResource_601150,
                                        base: "/", url: url_TagResource_601151,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601164 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601166(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601169 = header.getOrDefault("X-Amz-Target")
  valid_601169 = validateParameter(valid_601169, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.UntagResource"))
  if valid_601169 != nil:
    section.add "X-Amz-Target", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Content-Sha256", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Algorithm")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Algorithm", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Signature")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Signature", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-SignedHeaders", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Credential")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Credential", valid_601174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_UntagResource_601164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This action removes a tag from an Amazon FSx resource.
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_UntagResource_601164; body: JsonNode): Recallable =
  ## untagResource
  ## This action removes a tag from an Amazon FSx resource.
  ##   body: JObject (required)
  var body_601178 = newJObject()
  if body != nil:
    body_601178 = body
  result = call_601177.call(nil, nil, nil, nil, body_601178)

var untagResource* = Call_UntagResource_601164(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource",
    validator: validate_UntagResource_601165, base: "/", url: url_UntagResource_601166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_601179 = ref object of OpenApiRestCall_600426
proc url_UpdateFileSystem_601181(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFileSystem_601180(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601184 = header.getOrDefault("X-Amz-Target")
  valid_601184 = validateParameter(valid_601184, JString, required = true, default = newJString(
      "AWSSimbaAPIService_v20180301.UpdateFileSystem"))
  if valid_601184 != nil:
    section.add "X-Amz-Target", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Content-Sha256", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Algorithm")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Algorithm", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Signature")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Signature", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-SignedHeaders", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Credential")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Credential", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_UpdateFileSystem_601179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a file system configuration.
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_UpdateFileSystem_601179; body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates a file system configuration.
  ##   body: JObject (required)
  var body_601193 = newJObject()
  if body != nil:
    body_601193 = body
  result = call_601192.call(nil, nil, nil, nil, body_601193)

var updateFileSystem* = Call_UpdateFileSystem_601179(name: "updateFileSystem",
    meth: HttpMethod.HttpPost, host: "fsx.amazonaws.com",
    route: "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem",
    validator: validate_UpdateFileSystem_601180, base: "/",
    url: url_UpdateFileSystem_601181, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
