
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateFileSystem_601986 = ref object of OpenApiRestCall_601389
proc url_CreateFileSystem_601988(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFileSystem_601987(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601989 = header.getOrDefault("X-Amz-Signature")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Signature", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_CreateFileSystem_601986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ## 
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_CreateFileSystem_601986; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ##   body: JObject (required)
  var body_601999 = newJObject()
  if body != nil:
    body_601999 = body
  result = call_601998.call(nil, nil, nil, nil, body_601999)

var createFileSystem* = Call_CreateFileSystem_601986(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems", validator: validate_CreateFileSystem_601987,
    base: "/", url: url_CreateFileSystem_601988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_601727 = ref object of OpenApiRestCall_601389
proc url_DescribeFileSystems_601729(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFileSystems_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("FileSystemId")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "FileSystemId", valid_601841
  var valid_601842 = query.getOrDefault("Marker")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "Marker", valid_601842
  var valid_601843 = query.getOrDefault("MaxItems")
  valid_601843 = validateParameter(valid_601843, JInt, required = false, default = nil)
  if valid_601843 != nil:
    section.add "MaxItems", valid_601843
  var valid_601844 = query.getOrDefault("CreationToken")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "CreationToken", valid_601844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601845 = header.getOrDefault("X-Amz-Signature")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Signature", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Content-Sha256", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Date")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Date", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Security-Token")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Security-Token", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Algorithm")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Algorithm", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-SignedHeaders", valid_601851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601874: Call_DescribeFileSystems_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ## 
  let valid = call_601874.validator(path, query, header, formData, body)
  let scheme = call_601874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601874.url(scheme.get, call_601874.host, call_601874.base,
                         call_601874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601874, url, valid)

proc call*(call_601945: Call_DescribeFileSystems_601727; FileSystemId: string = "";
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
  var query_601946 = newJObject()
  add(query_601946, "FileSystemId", newJString(FileSystemId))
  add(query_601946, "Marker", newJString(Marker))
  add(query_601946, "MaxItems", newJInt(MaxItems))
  add(query_601946, "CreationToken", newJString(CreationToken))
  result = call_601945.call(nil, query_601946, nil, nil, nil)

var describeFileSystems* = Call_DescribeFileSystems_601727(
    name: "describeFileSystems", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_DescribeFileSystems_601728, base: "/",
    url: url_DescribeFileSystems_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMountTarget_602017 = ref object of OpenApiRestCall_601389
proc url_CreateMountTarget_602019(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMountTarget_602018(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602020 = header.getOrDefault("X-Amz-Signature")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Signature", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Content-Sha256", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Credential")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Credential", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Security-Token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Security-Token", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-SignedHeaders", valid_602026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_CreateMountTarget_602017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_CreateMountTarget_602017; body: JsonNode): Recallable =
  ## createMountTarget
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_602030 = newJObject()
  if body != nil:
    body_602030 = body
  result = call_602029.call(nil, nil, nil, nil, body_602030)

var createMountTarget* = Call_CreateMountTarget_602017(name: "createMountTarget",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets", validator: validate_CreateMountTarget_602018,
    base: "/", url: url_CreateMountTarget_602019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargets_602000 = ref object of OpenApiRestCall_601389
proc url_DescribeMountTargets_602002(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMountTargets_602001(path: JsonNode; query: JsonNode;
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
  ##   Marker: JString
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeMountTargets</code> operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  ##   MaxItems: JInt
  ##           : (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 mount targets.
  ##   MountTargetId: JString
  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included.
  section = newJObject()
  var valid_602003 = query.getOrDefault("FileSystemId")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "FileSystemId", valid_602003
  var valid_602004 = query.getOrDefault("Marker")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "Marker", valid_602004
  var valid_602005 = query.getOrDefault("MaxItems")
  valid_602005 = validateParameter(valid_602005, JInt, required = false, default = nil)
  if valid_602005 != nil:
    section.add "MaxItems", valid_602005
  var valid_602006 = query.getOrDefault("MountTargetId")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "MountTargetId", valid_602006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602007 = header.getOrDefault("X-Amz-Signature")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Signature", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Content-Sha256", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Credential")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Credential", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Security-Token")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Security-Token", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Algorithm")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Algorithm", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-SignedHeaders", valid_602013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_DescribeMountTargets_602000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602014, url, valid)

proc call*(call_602015: Call_DescribeMountTargets_602000;
          FileSystemId: string = ""; Marker: string = ""; MaxItems: int = 0;
          MountTargetId: string = ""): Recallable =
  ## describeMountTargets
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ##   FileSystemId: string
  ##               : (Optional) ID of the file system whose mount targets you want to list (String). It must be included in your request if <code>MountTargetId</code> is not included.
  ##   Marker: string
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeMountTargets</code> operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  ##   MaxItems: int
  ##           : (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 mount targets.
  ##   MountTargetId: string
  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included.
  var query_602016 = newJObject()
  add(query_602016, "FileSystemId", newJString(FileSystemId))
  add(query_602016, "Marker", newJString(Marker))
  add(query_602016, "MaxItems", newJInt(MaxItems))
  add(query_602016, "MountTargetId", newJString(MountTargetId))
  result = call_602015.call(nil, query_602016, nil, nil, nil)

var describeMountTargets* = Call_DescribeMountTargets_602000(
    name: "describeMountTargets", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_DescribeMountTargets_602001, base: "/",
    url: url_DescribeMountTargets_602002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_602031 = ref object of OpenApiRestCall_601389
proc url_CreateTags_602033(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_602032(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602048 = path.getOrDefault("FileSystemId")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "FileSystemId", valid_602048
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602049 = header.getOrDefault("X-Amz-Signature")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Signature", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Content-Sha256", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Date")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Date", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Credential")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Credential", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Security-Token")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Security-Token", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Algorithm")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Algorithm", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-SignedHeaders", valid_602055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602057: Call_CreateTags_602031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ## 
  let valid = call_602057.validator(path, query, header, formData, body)
  let scheme = call_602057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602057.url(scheme.get, call_602057.host, call_602057.base,
                         call_602057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602057, url, valid)

proc call*(call_602058: Call_CreateTags_602031; FileSystemId: string; body: JsonNode): Recallable =
  ## createTags
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to modify (String). This operation modifies the tags only, not the file system.
  ##   body: JObject (required)
  var path_602059 = newJObject()
  var body_602060 = newJObject()
  add(path_602059, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_602060 = body
  result = call_602058.call(path_602059, nil, nil, nil, body_602060)

var createTags* = Call_CreateTags_602031(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/create-tags/{FileSystemId}",
                                      validator: validate_CreateTags_602032,
                                      base: "/", url: url_CreateTags_602033,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_602061 = ref object of OpenApiRestCall_601389
proc url_UpdateFileSystem_602063(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFileSystem_602062(path: JsonNode; query: JsonNode;
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
  var valid_602064 = path.getOrDefault("FileSystemId")
  valid_602064 = validateParameter(valid_602064, JString, required = true,
                                 default = nil)
  if valid_602064 != nil:
    section.add "FileSystemId", valid_602064
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602065 = header.getOrDefault("X-Amz-Signature")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Signature", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Content-Sha256", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Date")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Date", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Credential")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Credential", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Security-Token")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Security-Token", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Algorithm")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Algorithm", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-SignedHeaders", valid_602071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_UpdateFileSystem_602061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_UpdateFileSystem_602061; FileSystemId: string;
          body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system that you want to update.
  ##   body: JObject (required)
  var path_602075 = newJObject()
  var body_602076 = newJObject()
  add(path_602075, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_602076 = body
  result = call_602074.call(path_602075, nil, nil, nil, body_602076)

var updateFileSystem* = Call_UpdateFileSystem_602061(name: "updateFileSystem",
    meth: HttpMethod.HttpPut, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_UpdateFileSystem_602062, base: "/",
    url: url_UpdateFileSystem_602063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_602077 = ref object of OpenApiRestCall_601389
proc url_DeleteFileSystem_602079(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFileSystem_602078(path: JsonNode; query: JsonNode;
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
  var valid_602080 = path.getOrDefault("FileSystemId")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "FileSystemId", valid_602080
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602081 = header.getOrDefault("X-Amz-Signature")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Signature", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Content-Sha256", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Date")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Date", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Credential")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Credential", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Security-Token")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Security-Token", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Algorithm")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Algorithm", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-SignedHeaders", valid_602087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602088: Call_DeleteFileSystem_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ## 
  let valid = call_602088.validator(path, query, header, formData, body)
  let scheme = call_602088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602088.url(scheme.get, call_602088.host, call_602088.base,
                         call_602088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602088, url, valid)

proc call*(call_602089: Call_DeleteFileSystem_602077; FileSystemId: string): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system you want to delete.
  var path_602090 = newJObject()
  add(path_602090, "FileSystemId", newJString(FileSystemId))
  result = call_602089.call(path_602090, nil, nil, nil, nil)

var deleteFileSystem* = Call_DeleteFileSystem_602077(name: "deleteFileSystem",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_DeleteFileSystem_602078, base: "/",
    url: url_DeleteFileSystem_602079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMountTarget_602091 = ref object of OpenApiRestCall_601389
proc url_DeleteMountTarget_602093(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMountTarget_602092(path: JsonNode; query: JsonNode;
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
  var valid_602094 = path.getOrDefault("MountTargetId")
  valid_602094 = validateParameter(valid_602094, JString, required = true,
                                 default = nil)
  if valid_602094 != nil:
    section.add "MountTargetId", valid_602094
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602095 = header.getOrDefault("X-Amz-Signature")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Signature", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Content-Sha256", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Date")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Date", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Credential")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Credential", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Security-Token")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Security-Token", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Algorithm")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Algorithm", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-SignedHeaders", valid_602101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602102: Call_DeleteMountTarget_602091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_602102.validator(path, query, header, formData, body)
  let scheme = call_602102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602102.url(scheme.get, call_602102.host, call_602102.base,
                         call_602102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602102, url, valid)

proc call*(call_602103: Call_DeleteMountTarget_602091; MountTargetId: string): Recallable =
  ## deleteMountTarget
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target to delete (String).
  var path_602104 = newJObject()
  add(path_602104, "MountTargetId", newJString(MountTargetId))
  result = call_602103.call(path_602104, nil, nil, nil, nil)

var deleteMountTarget* = Call_DeleteMountTarget_602091(name: "deleteMountTarget",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}",
    validator: validate_DeleteMountTarget_602092, base: "/",
    url: url_DeleteMountTarget_602093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_602105 = ref object of OpenApiRestCall_601389
proc url_DeleteTags_602107(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_602106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602108 = path.getOrDefault("FileSystemId")
  valid_602108 = validateParameter(valid_602108, JString, required = true,
                                 default = nil)
  if valid_602108 != nil:
    section.add "FileSystemId", valid_602108
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602109 = header.getOrDefault("X-Amz-Signature")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Signature", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Content-Sha256", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Date")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Date", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Credential")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Credential", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Security-Token")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Security-Token", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Algorithm")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Algorithm", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-SignedHeaders", valid_602115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602117: Call_DeleteTags_602105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ## 
  let valid = call_602117.validator(path, query, header, formData, body)
  let scheme = call_602117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602117.url(scheme.get, call_602117.host, call_602117.base,
                         call_602117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602117, url, valid)

proc call*(call_602118: Call_DeleteTags_602105; FileSystemId: string; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to delete (String).
  ##   body: JObject (required)
  var path_602119 = newJObject()
  var body_602120 = newJObject()
  add(path_602119, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_602120 = body
  result = call_602118.call(path_602119, nil, nil, nil, body_602120)

var deleteTags* = Call_DeleteTags_602105(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/delete-tags/{FileSystemId}",
                                      validator: validate_DeleteTags_602106,
                                      base: "/", url: url_DeleteTags_602107,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleConfiguration_602135 = ref object of OpenApiRestCall_601389
proc url_PutLifecycleConfiguration_602137(protocol: Scheme; host: string;
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

proc validate_PutLifecycleConfiguration_602136(path: JsonNode; query: JsonNode;
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
  var valid_602138 = path.getOrDefault("FileSystemId")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "FileSystemId", valid_602138
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_PutLifecycleConfiguration_602135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602147, url, valid)

proc call*(call_602148: Call_PutLifecycleConfiguration_602135;
          FileSystemId: string; body: JsonNode): Recallable =
  ## putLifecycleConfiguration
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system for which you are creating the <code>LifecycleConfiguration</code> object (String).
  ##   body: JObject (required)
  var path_602149 = newJObject()
  var body_602150 = newJObject()
  add(path_602149, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_602150 = body
  result = call_602148.call(path_602149, nil, nil, nil, body_602150)

var putLifecycleConfiguration* = Call_PutLifecycleConfiguration_602135(
    name: "putLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_PutLifecycleConfiguration_602136, base: "/",
    url: url_PutLifecycleConfiguration_602137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLifecycleConfiguration_602121 = ref object of OpenApiRestCall_601389
proc url_DescribeLifecycleConfiguration_602123(protocol: Scheme; host: string;
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

proc validate_DescribeLifecycleConfiguration_602122(path: JsonNode;
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
  var valid_602124 = path.getOrDefault("FileSystemId")
  valid_602124 = validateParameter(valid_602124, JString, required = true,
                                 default = nil)
  if valid_602124 != nil:
    section.add "FileSystemId", valid_602124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602125 = header.getOrDefault("X-Amz-Signature")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Signature", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Content-Sha256", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Date")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Date", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Credential")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Credential", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Security-Token")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Security-Token", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Algorithm")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Algorithm", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-SignedHeaders", valid_602131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602132: Call_DescribeLifecycleConfiguration_602121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ## 
  let valid = call_602132.validator(path, query, header, formData, body)
  let scheme = call_602132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602132.url(scheme.get, call_602132.host, call_602132.base,
                         call_602132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602132, url, valid)

proc call*(call_602133: Call_DescribeLifecycleConfiguration_602121;
          FileSystemId: string): Recallable =
  ## describeLifecycleConfiguration
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose <code>LifecycleConfiguration</code> object you want to retrieve (String).
  var path_602134 = newJObject()
  add(path_602134, "FileSystemId", newJString(FileSystemId))
  result = call_602133.call(path_602134, nil, nil, nil, nil)

var describeLifecycleConfiguration* = Call_DescribeLifecycleConfiguration_602121(
    name: "describeLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_DescribeLifecycleConfiguration_602122, base: "/",
    url: url_DescribeLifecycleConfiguration_602123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyMountTargetSecurityGroups_602165 = ref object of OpenApiRestCall_601389
proc url_ModifyMountTargetSecurityGroups_602167(protocol: Scheme; host: string;
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

proc validate_ModifyMountTargetSecurityGroups_602166(path: JsonNode;
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
  var valid_602168 = path.getOrDefault("MountTargetId")
  valid_602168 = validateParameter(valid_602168, JString, required = true,
                                 default = nil)
  if valid_602168 != nil:
    section.add "MountTargetId", valid_602168
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602169 = header.getOrDefault("X-Amz-Signature")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Signature", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Content-Sha256", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Date")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Date", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Credential")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Credential", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Security-Token")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Security-Token", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Algorithm")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Algorithm", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-SignedHeaders", valid_602175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602177: Call_ModifyMountTargetSecurityGroups_602165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_602177.validator(path, query, header, formData, body)
  let scheme = call_602177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602177.url(scheme.get, call_602177.host, call_602177.base,
                         call_602177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602177, url, valid)

proc call*(call_602178: Call_ModifyMountTargetSecurityGroups_602165;
          MountTargetId: string; body: JsonNode): Recallable =
  ## modifyMountTargetSecurityGroups
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to modify.
  ##   body: JObject (required)
  var path_602179 = newJObject()
  var body_602180 = newJObject()
  add(path_602179, "MountTargetId", newJString(MountTargetId))
  if body != nil:
    body_602180 = body
  result = call_602178.call(path_602179, nil, nil, nil, body_602180)

var modifyMountTargetSecurityGroups* = Call_ModifyMountTargetSecurityGroups_602165(
    name: "modifyMountTargetSecurityGroups", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_ModifyMountTargetSecurityGroups_602166, base: "/",
    url: url_ModifyMountTargetSecurityGroups_602167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargetSecurityGroups_602151 = ref object of OpenApiRestCall_601389
proc url_DescribeMountTargetSecurityGroups_602153(protocol: Scheme; host: string;
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

proc validate_DescribeMountTargetSecurityGroups_602152(path: JsonNode;
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
  var valid_602154 = path.getOrDefault("MountTargetId")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = nil)
  if valid_602154 != nil:
    section.add "MountTargetId", valid_602154
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602155 = header.getOrDefault("X-Amz-Signature")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Signature", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Content-Sha256", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Date")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Date", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Credential")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Credential", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Security-Token")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Security-Token", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-SignedHeaders", valid_602161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_DescribeMountTargetSecurityGroups_602151;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_DescribeMountTargetSecurityGroups_602151;
          MountTargetId: string): Recallable =
  ## describeMountTargetSecurityGroups
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to retrieve.
  var path_602164 = newJObject()
  add(path_602164, "MountTargetId", newJString(MountTargetId))
  result = call_602163.call(path_602164, nil, nil, nil, nil)

var describeMountTargetSecurityGroups* = Call_DescribeMountTargetSecurityGroups_602151(
    name: "describeMountTargetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_DescribeMountTargetSecurityGroups_602152, base: "/",
    url: url_DescribeMountTargetSecurityGroups_602153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_602181 = ref object of OpenApiRestCall_601389
proc url_DescribeTags_602183(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_602182(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602184 = path.getOrDefault("FileSystemId")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "FileSystemId", valid_602184
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: JInt
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  section = newJObject()
  var valid_602185 = query.getOrDefault("Marker")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "Marker", valid_602185
  var valid_602186 = query.getOrDefault("MaxItems")
  valid_602186 = validateParameter(valid_602186, JInt, required = false, default = nil)
  if valid_602186 != nil:
    section.add "MaxItems", valid_602186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602187 = header.getOrDefault("X-Amz-Signature")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Signature", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Content-Sha256", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Date")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Date", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Credential")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Credential", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Security-Token")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Security-Token", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Algorithm")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Algorithm", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-SignedHeaders", valid_602193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602194: Call_DescribeTags_602181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ## 
  let valid = call_602194.validator(path, query, header, formData, body)
  let scheme = call_602194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602194.url(scheme.get, call_602194.host, call_602194.base,
                         call_602194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602194, url, valid)

proc call*(call_602195: Call_DescribeTags_602181; FileSystemId: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## describeTags
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ##   Marker: string
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: int
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tag set you want to retrieve.
  var path_602196 = newJObject()
  var query_602197 = newJObject()
  add(query_602197, "Marker", newJString(Marker))
  add(query_602197, "MaxItems", newJInt(MaxItems))
  add(path_602196, "FileSystemId", newJString(FileSystemId))
  result = call_602195.call(path_602196, query_602197, nil, nil, nil)

var describeTags* = Call_DescribeTags_602181(name: "describeTags",
    meth: HttpMethod.HttpGet, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/tags/{FileSystemId}/", validator: validate_DescribeTags_602182,
    base: "/", url: url_DescribeTags_602183, schemes: {Scheme.Https, Scheme.Http})
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
