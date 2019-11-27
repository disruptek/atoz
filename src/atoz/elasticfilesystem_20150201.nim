
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic File System
## version: 2015-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elastic File System</fullname> <p>Amazon Elastic File System (Amazon EFS) provides simple, scalable file storage for use with Amazon EC2 instances in the AWS Cloud. With Amazon EFS, storage capacity is elastic, growing and shrinking automatically as you add and remove files, so your applications have the storage they need, when they need it. For more information, see the <a href="https://docs.aws.amazon.com/efs/latest/ug/api-reference.html">User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elasticfilesystem/
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elasticfilesystem.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticfilesystem.ap-southeast-1.amazonaws.com", "us-west-2": "elasticfilesystem.us-west-2.amazonaws.com", "eu-west-2": "elasticfilesystem.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticfilesystem.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticfilesystem.eu-central-1.amazonaws.com", "us-east-2": "elasticfilesystem.us-east-2.amazonaws.com", "us-east-1": "elasticfilesystem.us-east-1.amazonaws.com", "cn-northwest-1": "elasticfilesystem.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticfilesystem.ap-south-1.amazonaws.com", "eu-north-1": "elasticfilesystem.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticfilesystem.ap-northeast-2.amazonaws.com", "us-west-1": "elasticfilesystem.us-west-1.amazonaws.com", "us-gov-east-1": "elasticfilesystem.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticfilesystem.eu-west-3.amazonaws.com", "cn-north-1": "elasticfilesystem.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticfilesystem.sa-east-1.amazonaws.com", "eu-west-1": "elasticfilesystem.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticfilesystem.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticfilesystem.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticfilesystem.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elasticfilesystem.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elasticfilesystem.ap-southeast-1.amazonaws.com",
      "us-west-2": "elasticfilesystem.us-west-2.amazonaws.com",
      "eu-west-2": "elasticfilesystem.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elasticfilesystem.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elasticfilesystem.eu-central-1.amazonaws.com",
      "us-east-2": "elasticfilesystem.us-east-2.amazonaws.com",
      "us-east-1": "elasticfilesystem.us-east-1.amazonaws.com",
      "cn-northwest-1": "elasticfilesystem.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elasticfilesystem.ap-south-1.amazonaws.com",
      "eu-north-1": "elasticfilesystem.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elasticfilesystem.ap-northeast-2.amazonaws.com",
      "us-west-1": "elasticfilesystem.us-west-1.amazonaws.com",
      "us-gov-east-1": "elasticfilesystem.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elasticfilesystem.eu-west-3.amazonaws.com",
      "cn-north-1": "elasticfilesystem.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elasticfilesystem.sa-east-1.amazonaws.com",
      "eu-west-1": "elasticfilesystem.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elasticfilesystem.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elasticfilesystem.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elasticfilesystem.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elasticfilesystem"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateFileSystem_599964 = ref object of OpenApiRestCall_599368
proc url_CreateFileSystem_599966(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFileSystem_599965(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599967 = header.getOrDefault("X-Amz-Date")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Date", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Security-Token")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Security-Token", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Content-Sha256", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Algorithm")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Algorithm", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Signature")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Signature", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-SignedHeaders", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Credential")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Credential", valid_599973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599975: Call_CreateFileSystem_599964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ## 
  let valid = call_599975.validator(path, query, header, formData, body)
  let scheme = call_599975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599975.url(scheme.get, call_599975.host, call_599975.base,
                         call_599975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599975, url, valid)

proc call*(call_599976: Call_CreateFileSystem_599964; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ##   body: JObject (required)
  var body_599977 = newJObject()
  if body != nil:
    body_599977 = body
  result = call_599976.call(nil, nil, nil, nil, body_599977)

var createFileSystem* = Call_CreateFileSystem_599964(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems", validator: validate_CreateFileSystem_599965,
    base: "/", url: url_CreateFileSystem_599966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_599705 = ref object of OpenApiRestCall_599368
proc url_DescribeFileSystems_599707(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFileSystems_599706(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FileSystemId: JString
  ##               : (Optional) ID of the file system whose description you want to retrieve (String).
  ##   Marker: JString
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeFileSystems</code> operation (String). If present, specifies to continue the list from where the returning call had left off. 
  ##   MaxItems: JInt
  ##           : (Optional) Specifies the maximum number of file systems to return in the response (integer). Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 file systems. 
  ##   CreationToken: JString
  ##                : (Optional) Restricts the list to the file system with this creation token (String). You specify a creation token when you create an Amazon EFS file system.
  section = newJObject()
  var valid_599819 = query.getOrDefault("FileSystemId")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "FileSystemId", valid_599819
  var valid_599820 = query.getOrDefault("Marker")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "Marker", valid_599820
  var valid_599821 = query.getOrDefault("MaxItems")
  valid_599821 = validateParameter(valid_599821, JInt, required = false, default = nil)
  if valid_599821 != nil:
    section.add "MaxItems", valid_599821
  var valid_599822 = query.getOrDefault("CreationToken")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "CreationToken", valid_599822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599823 = header.getOrDefault("X-Amz-Date")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Date", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Security-Token")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Security-Token", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Content-Sha256", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Algorithm")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Algorithm", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Signature")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Signature", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-SignedHeaders", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-Credential")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-Credential", valid_599829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599852: Call_DescribeFileSystems_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ## 
  let valid = call_599852.validator(path, query, header, formData, body)
  let scheme = call_599852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599852.url(scheme.get, call_599852.host, call_599852.base,
                         call_599852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599852, url, valid)

proc call*(call_599923: Call_DescribeFileSystems_599705; FileSystemId: string = "";
          Marker: string = ""; MaxItems: int = 0; CreationToken: string = ""): Recallable =
  ## describeFileSystems
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ##   FileSystemId: string
  ##               : (Optional) ID of the file system whose description you want to retrieve (String).
  ##   Marker: string
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeFileSystems</code> operation (String). If present, specifies to continue the list from where the returning call had left off. 
  ##   MaxItems: int
  ##           : (Optional) Specifies the maximum number of file systems to return in the response (integer). Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 file systems. 
  ##   CreationToken: string
  ##                : (Optional) Restricts the list to the file system with this creation token (String). You specify a creation token when you create an Amazon EFS file system.
  var query_599924 = newJObject()
  add(query_599924, "FileSystemId", newJString(FileSystemId))
  add(query_599924, "Marker", newJString(Marker))
  add(query_599924, "MaxItems", newJInt(MaxItems))
  add(query_599924, "CreationToken", newJString(CreationToken))
  result = call_599923.call(nil, query_599924, nil, nil, nil)

var describeFileSystems* = Call_DescribeFileSystems_599705(
    name: "describeFileSystems", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_DescribeFileSystems_599706, base: "/",
    url: url_DescribeFileSystems_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMountTarget_599995 = ref object of OpenApiRestCall_599368
proc url_CreateMountTarget_599997(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMountTarget_599996(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599998 = header.getOrDefault("X-Amz-Date")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Date", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Security-Token")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Security-Token", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Content-Sha256", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Algorithm")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Algorithm", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Signature")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Signature", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-SignedHeaders", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Credential")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Credential", valid_600004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_CreateMountTarget_599995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_CreateMountTarget_599995; body: JsonNode): Recallable =
  ## createMountTarget
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_600008 = newJObject()
  if body != nil:
    body_600008 = body
  result = call_600007.call(nil, nil, nil, nil, body_600008)

var createMountTarget* = Call_CreateMountTarget_599995(name: "createMountTarget",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets", validator: validate_CreateMountTarget_599996,
    base: "/", url: url_CreateMountTarget_599997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargets_599978 = ref object of OpenApiRestCall_599368
proc url_DescribeMountTargets_599980(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMountTargets_599979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FileSystemId: JString
  ##               : (Optional) ID of the file system whose mount targets you want to list (String). It must be included in your request if <code>MountTargetId</code> is not included.
  ##   MountTargetId: JString
  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included.
  ##   Marker: JString
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeMountTargets</code> operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  ##   MaxItems: JInt
  ##           : (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 mount targets.
  section = newJObject()
  var valid_599981 = query.getOrDefault("FileSystemId")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "FileSystemId", valid_599981
  var valid_599982 = query.getOrDefault("MountTargetId")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "MountTargetId", valid_599982
  var valid_599983 = query.getOrDefault("Marker")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "Marker", valid_599983
  var valid_599984 = query.getOrDefault("MaxItems")
  valid_599984 = validateParameter(valid_599984, JInt, required = false, default = nil)
  if valid_599984 != nil:
    section.add "MaxItems", valid_599984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599985 = header.getOrDefault("X-Amz-Date")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Date", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Security-Token")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Security-Token", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Content-Sha256", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Algorithm")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Algorithm", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Signature")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Signature", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-SignedHeaders", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Credential")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Credential", valid_599991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_DescribeMountTargets_599978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_DescribeMountTargets_599978;
          FileSystemId: string = ""; MountTargetId: string = ""; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## describeMountTargets
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ##   FileSystemId: string
  ##               : (Optional) ID of the file system whose mount targets you want to list (String). It must be included in your request if <code>MountTargetId</code> is not included.
  ##   MountTargetId: string
  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included.
  ##   Marker: string
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeMountTargets</code> operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  ##   MaxItems: int
  ##           : (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 mount targets.
  var query_599994 = newJObject()
  add(query_599994, "FileSystemId", newJString(FileSystemId))
  add(query_599994, "MountTargetId", newJString(MountTargetId))
  add(query_599994, "Marker", newJString(Marker))
  add(query_599994, "MaxItems", newJInt(MaxItems))
  result = call_599993.call(nil, query_599994, nil, nil, nil)

var describeMountTargets* = Call_DescribeMountTargets_599978(
    name: "describeMountTargets", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_DescribeMountTargets_599979, base: "/",
    url: url_DescribeMountTargets_599980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_600009 = ref object of OpenApiRestCall_599368
proc url_CreateTags_600011(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/create-tags/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_600010(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system whose tags you want to modify (String). This operation modifies the tags only, not the file system.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600026 = path.getOrDefault("FileSystemId")
  valid_600026 = validateParameter(valid_600026, JString, required = true,
                                 default = nil)
  if valid_600026 != nil:
    section.add "FileSystemId", valid_600026
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600027 = header.getOrDefault("X-Amz-Date")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Date", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Security-Token")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Security-Token", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Content-Sha256", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Algorithm")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Algorithm", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Signature")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Signature", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-SignedHeaders", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Credential")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Credential", valid_600033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600035: Call_CreateTags_600009; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ## 
  let valid = call_600035.validator(path, query, header, formData, body)
  let scheme = call_600035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600035.url(scheme.get, call_600035.host, call_600035.base,
                         call_600035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600035, url, valid)

proc call*(call_600036: Call_CreateTags_600009; FileSystemId: string; body: JsonNode): Recallable =
  ## createTags
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to modify (String). This operation modifies the tags only, not the file system.
  ##   body: JObject (required)
  var path_600037 = newJObject()
  var body_600038 = newJObject()
  add(path_600037, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_600038 = body
  result = call_600036.call(path_600037, nil, nil, nil, body_600038)

var createTags* = Call_CreateTags_600009(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/create-tags/{FileSystemId}",
                                      validator: validate_CreateTags_600010,
                                      base: "/", url: url_CreateTags_600011,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_600039 = ref object of OpenApiRestCall_599368
proc url_UpdateFileSystem_600041(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFileSystem_600040(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600042 = path.getOrDefault("FileSystemId")
  valid_600042 = validateParameter(valid_600042, JString, required = true,
                                 default = nil)
  if valid_600042 != nil:
    section.add "FileSystemId", valid_600042
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600043 = header.getOrDefault("X-Amz-Date")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Date", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Security-Token")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Security-Token", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Content-Sha256", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Algorithm")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Algorithm", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Signature")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Signature", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-SignedHeaders", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Credential")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Credential", valid_600049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600051: Call_UpdateFileSystem_600039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ## 
  let valid = call_600051.validator(path, query, header, formData, body)
  let scheme = call_600051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600051.url(scheme.get, call_600051.host, call_600051.base,
                         call_600051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600051, url, valid)

proc call*(call_600052: Call_UpdateFileSystem_600039; FileSystemId: string;
          body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system that you want to update.
  ##   body: JObject (required)
  var path_600053 = newJObject()
  var body_600054 = newJObject()
  add(path_600053, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_600054 = body
  result = call_600052.call(path_600053, nil, nil, nil, body_600054)

var updateFileSystem* = Call_UpdateFileSystem_600039(name: "updateFileSystem",
    meth: HttpMethod.HttpPut, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_UpdateFileSystem_600040, base: "/",
    url: url_UpdateFileSystem_600041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_600055 = ref object of OpenApiRestCall_599368
proc url_DeleteFileSystem_600057(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFileSystem_600056(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600058 = path.getOrDefault("FileSystemId")
  valid_600058 = validateParameter(valid_600058, JString, required = true,
                                 default = nil)
  if valid_600058 != nil:
    section.add "FileSystemId", valid_600058
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600059 = header.getOrDefault("X-Amz-Date")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Date", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Security-Token")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Security-Token", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Content-Sha256", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Algorithm")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Algorithm", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Signature")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Signature", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-SignedHeaders", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Credential")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Credential", valid_600065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600066: Call_DeleteFileSystem_600055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ## 
  let valid = call_600066.validator(path, query, header, formData, body)
  let scheme = call_600066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600066.url(scheme.get, call_600066.host, call_600066.base,
                         call_600066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600066, url, valid)

proc call*(call_600067: Call_DeleteFileSystem_600055; FileSystemId: string): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system you want to delete.
  var path_600068 = newJObject()
  add(path_600068, "FileSystemId", newJString(FileSystemId))
  result = call_600067.call(path_600068, nil, nil, nil, nil)

var deleteFileSystem* = Call_DeleteFileSystem_600055(name: "deleteFileSystem",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_DeleteFileSystem_600056, base: "/",
    url: url_DeleteFileSystem_600057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMountTarget_600069 = ref object of OpenApiRestCall_599368
proc url_DeleteMountTarget_600071(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "MountTargetId" in path, "`MountTargetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/mount-targets/"),
               (kind: VariableSegment, value: "MountTargetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMountTarget_600070(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   MountTargetId: JString (required)
  ##                : The ID of the mount target to delete (String).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `MountTargetId` field"
  var valid_600072 = path.getOrDefault("MountTargetId")
  valid_600072 = validateParameter(valid_600072, JString, required = true,
                                 default = nil)
  if valid_600072 != nil:
    section.add "MountTargetId", valid_600072
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600073 = header.getOrDefault("X-Amz-Date")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Date", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Security-Token")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Security-Token", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Content-Sha256", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Algorithm")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Algorithm", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Signature")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Signature", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-SignedHeaders", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Credential")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Credential", valid_600079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600080: Call_DeleteMountTarget_600069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_600080.validator(path, query, header, formData, body)
  let scheme = call_600080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600080.url(scheme.get, call_600080.host, call_600080.base,
                         call_600080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600080, url, valid)

proc call*(call_600081: Call_DeleteMountTarget_600069; MountTargetId: string): Recallable =
  ## deleteMountTarget
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target to delete (String).
  var path_600082 = newJObject()
  add(path_600082, "MountTargetId", newJString(MountTargetId))
  result = call_600081.call(path_600082, nil, nil, nil, nil)

var deleteMountTarget* = Call_DeleteMountTarget_600069(name: "deleteMountTarget",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}",
    validator: validate_DeleteMountTarget_600070, base: "/",
    url: url_DeleteMountTarget_600071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_600083 = ref object of OpenApiRestCall_599368
proc url_DeleteTags_600085(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/delete-tags/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_600084(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system whose tags you want to delete (String).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600086 = path.getOrDefault("FileSystemId")
  valid_600086 = validateParameter(valid_600086, JString, required = true,
                                 default = nil)
  if valid_600086 != nil:
    section.add "FileSystemId", valid_600086
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600087 = header.getOrDefault("X-Amz-Date")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Date", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Security-Token")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Security-Token", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Content-Sha256", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Algorithm")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Algorithm", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Signature")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Signature", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-SignedHeaders", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Credential")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Credential", valid_600093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_DeleteTags_600083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_DeleteTags_600083; FileSystemId: string; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to delete (String).
  ##   body: JObject (required)
  var path_600097 = newJObject()
  var body_600098 = newJObject()
  add(path_600097, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_600098 = body
  result = call_600096.call(path_600097, nil, nil, nil, body_600098)

var deleteTags* = Call_DeleteTags_600083(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/delete-tags/{FileSystemId}",
                                      validator: validate_DeleteTags_600084,
                                      base: "/", url: url_DeleteTags_600085,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleConfiguration_600113 = ref object of OpenApiRestCall_599368
proc url_PutLifecycleConfiguration_600115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/lifecycle-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutLifecycleConfiguration_600114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system for which you are creating the <code>LifecycleConfiguration</code> object (String).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600116 = path.getOrDefault("FileSystemId")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = nil)
  if valid_600116 != nil:
    section.add "FileSystemId", valid_600116
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600117 = header.getOrDefault("X-Amz-Date")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Date", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Security-Token")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Security-Token", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Content-Sha256", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Algorithm")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Algorithm", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Signature", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-SignedHeaders", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Credential")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Credential", valid_600123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600125: Call_PutLifecycleConfiguration_600113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ## 
  let valid = call_600125.validator(path, query, header, formData, body)
  let scheme = call_600125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600125.url(scheme.get, call_600125.host, call_600125.base,
                         call_600125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600125, url, valid)

proc call*(call_600126: Call_PutLifecycleConfiguration_600113;
          FileSystemId: string; body: JsonNode): Recallable =
  ## putLifecycleConfiguration
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system for which you are creating the <code>LifecycleConfiguration</code> object (String).
  ##   body: JObject (required)
  var path_600127 = newJObject()
  var body_600128 = newJObject()
  add(path_600127, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_600128 = body
  result = call_600126.call(path_600127, nil, nil, nil, body_600128)

var putLifecycleConfiguration* = Call_PutLifecycleConfiguration_600113(
    name: "putLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_PutLifecycleConfiguration_600114, base: "/",
    url: url_PutLifecycleConfiguration_600115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLifecycleConfiguration_600099 = ref object of OpenApiRestCall_599368
proc url_DescribeLifecycleConfiguration_600101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/lifecycle-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeLifecycleConfiguration_600100(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system whose <code>LifecycleConfiguration</code> object you want to retrieve (String).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600102 = path.getOrDefault("FileSystemId")
  valid_600102 = validateParameter(valid_600102, JString, required = true,
                                 default = nil)
  if valid_600102 != nil:
    section.add "FileSystemId", valid_600102
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600103 = header.getOrDefault("X-Amz-Date")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Date", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Security-Token")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Security-Token", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Content-Sha256", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Algorithm")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Algorithm", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Signature", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-SignedHeaders", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Credential")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Credential", valid_600109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600110: Call_DescribeLifecycleConfiguration_600099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ## 
  let valid = call_600110.validator(path, query, header, formData, body)
  let scheme = call_600110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600110.url(scheme.get, call_600110.host, call_600110.base,
                         call_600110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600110, url, valid)

proc call*(call_600111: Call_DescribeLifecycleConfiguration_600099;
          FileSystemId: string): Recallable =
  ## describeLifecycleConfiguration
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose <code>LifecycleConfiguration</code> object you want to retrieve (String).
  var path_600112 = newJObject()
  add(path_600112, "FileSystemId", newJString(FileSystemId))
  result = call_600111.call(path_600112, nil, nil, nil, nil)

var describeLifecycleConfiguration* = Call_DescribeLifecycleConfiguration_600099(
    name: "describeLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_DescribeLifecycleConfiguration_600100, base: "/",
    url: url_DescribeLifecycleConfiguration_600101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyMountTargetSecurityGroups_600143 = ref object of OpenApiRestCall_599368
proc url_ModifyMountTargetSecurityGroups_600145(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "MountTargetId" in path, "`MountTargetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/mount-targets/"),
               (kind: VariableSegment, value: "MountTargetId"),
               (kind: ConstantSegment, value: "/security-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ModifyMountTargetSecurityGroups_600144(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   MountTargetId: JString (required)
  ##                : The ID of the mount target whose security groups you want to modify.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `MountTargetId` field"
  var valid_600146 = path.getOrDefault("MountTargetId")
  valid_600146 = validateParameter(valid_600146, JString, required = true,
                                 default = nil)
  if valid_600146 != nil:
    section.add "MountTargetId", valid_600146
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600147 = header.getOrDefault("X-Amz-Date")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Date", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Security-Token")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Security-Token", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Content-Sha256", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Algorithm")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Algorithm", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Signature")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Signature", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-SignedHeaders", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Credential")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Credential", valid_600153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600155: Call_ModifyMountTargetSecurityGroups_600143;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_600155.validator(path, query, header, formData, body)
  let scheme = call_600155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600155.url(scheme.get, call_600155.host, call_600155.base,
                         call_600155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600155, url, valid)

proc call*(call_600156: Call_ModifyMountTargetSecurityGroups_600143;
          MountTargetId: string; body: JsonNode): Recallable =
  ## modifyMountTargetSecurityGroups
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to modify.
  ##   body: JObject (required)
  var path_600157 = newJObject()
  var body_600158 = newJObject()
  add(path_600157, "MountTargetId", newJString(MountTargetId))
  if body != nil:
    body_600158 = body
  result = call_600156.call(path_600157, nil, nil, nil, body_600158)

var modifyMountTargetSecurityGroups* = Call_ModifyMountTargetSecurityGroups_600143(
    name: "modifyMountTargetSecurityGroups", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_ModifyMountTargetSecurityGroups_600144, base: "/",
    url: url_ModifyMountTargetSecurityGroups_600145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargetSecurityGroups_600129 = ref object of OpenApiRestCall_599368
proc url_DescribeMountTargetSecurityGroups_600131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "MountTargetId" in path, "`MountTargetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/mount-targets/"),
               (kind: VariableSegment, value: "MountTargetId"),
               (kind: ConstantSegment, value: "/security-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMountTargetSecurityGroups_600130(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   MountTargetId: JString (required)
  ##                : The ID of the mount target whose security groups you want to retrieve.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `MountTargetId` field"
  var valid_600132 = path.getOrDefault("MountTargetId")
  valid_600132 = validateParameter(valid_600132, JString, required = true,
                                 default = nil)
  if valid_600132 != nil:
    section.add "MountTargetId", valid_600132
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600133 = header.getOrDefault("X-Amz-Date")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Date", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Security-Token")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Security-Token", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Content-Sha256", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Algorithm")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Algorithm", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Signature")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Signature", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-SignedHeaders", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Credential")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Credential", valid_600139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600140: Call_DescribeMountTargetSecurityGroups_600129;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_600140.validator(path, query, header, formData, body)
  let scheme = call_600140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600140.url(scheme.get, call_600140.host, call_600140.base,
                         call_600140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600140, url, valid)

proc call*(call_600141: Call_DescribeMountTargetSecurityGroups_600129;
          MountTargetId: string): Recallable =
  ## describeMountTargetSecurityGroups
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to retrieve.
  var path_600142 = newJObject()
  add(path_600142, "MountTargetId", newJString(MountTargetId))
  result = call_600141.call(path_600142, nil, nil, nil, nil)

var describeMountTargetSecurityGroups* = Call_DescribeMountTargetSecurityGroups_600129(
    name: "describeMountTargetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_DescribeMountTargetSecurityGroups_600130, base: "/",
    url: url_DescribeMountTargetSecurityGroups_600131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_600159 = ref object of OpenApiRestCall_599368
proc url_DescribeTags_600161(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/tags/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTags_600160(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the file system whose tag set you want to retrieve.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_600162 = path.getOrDefault("FileSystemId")
  valid_600162 = validateParameter(valid_600162, JString, required = true,
                                 default = nil)
  if valid_600162 != nil:
    section.add "FileSystemId", valid_600162
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: JInt
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  section = newJObject()
  var valid_600163 = query.getOrDefault("Marker")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "Marker", valid_600163
  var valid_600164 = query.getOrDefault("MaxItems")
  valid_600164 = validateParameter(valid_600164, JInt, required = false, default = nil)
  if valid_600164 != nil:
    section.add "MaxItems", valid_600164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600165 = header.getOrDefault("X-Amz-Date")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Date", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Security-Token")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Security-Token", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Content-Sha256", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Algorithm")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Algorithm", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Signature")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Signature", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-SignedHeaders", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Credential")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Credential", valid_600171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600172: Call_DescribeTags_600159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ## 
  let valid = call_600172.validator(path, query, header, formData, body)
  let scheme = call_600172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600172.url(scheme.get, call_600172.host, call_600172.base,
                         call_600172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600172, url, valid)

proc call*(call_600173: Call_DescribeTags_600159; FileSystemId: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## describeTags
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tag set you want to retrieve.
  ##   Marker: string
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: int
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  var path_600174 = newJObject()
  var query_600175 = newJObject()
  add(path_600174, "FileSystemId", newJString(FileSystemId))
  add(query_600175, "Marker", newJString(Marker))
  add(query_600175, "MaxItems", newJInt(MaxItems))
  result = call_600173.call(path_600174, query_600175, nil, nil, nil)

var describeTags* = Call_DescribeTags_600159(name: "describeTags",
    meth: HttpMethod.HttpGet, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/tags/{FileSystemId}/", validator: validate_DescribeTags_600160,
    base: "/", url: url_DescribeTags_600161, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
