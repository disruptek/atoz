
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateFileSystem_593986 = ref object of OpenApiRestCall_593389
proc url_CreateFileSystem_593988(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFileSystem_593987(path: JsonNode; query: JsonNode;
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
  var valid_593989 = header.getOrDefault("X-Amz-Signature")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Signature", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Content-Sha256", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-Date")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-Date", valid_593991
  var valid_593992 = header.getOrDefault("X-Amz-Credential")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "X-Amz-Credential", valid_593992
  var valid_593993 = header.getOrDefault("X-Amz-Security-Token")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Security-Token", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-Algorithm")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-Algorithm", valid_593994
  var valid_593995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593995 = validateParameter(valid_593995, JString, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "X-Amz-SignedHeaders", valid_593995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593997: Call_CreateFileSystem_593986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ## 
  let valid = call_593997.validator(path, query, header, formData, body)
  let scheme = call_593997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593997.url(scheme.get, call_593997.host, call_593997.base,
                         call_593997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593997, url, valid)

proc call*(call_593998: Call_CreateFileSystem_593986; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ##   body: JObject (required)
  var body_593999 = newJObject()
  if body != nil:
    body_593999 = body
  result = call_593998.call(nil, nil, nil, nil, body_593999)

var createFileSystem* = Call_CreateFileSystem_593986(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems", validator: validate_CreateFileSystem_593987,
    base: "/", url: url_CreateFileSystem_593988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_593727 = ref object of OpenApiRestCall_593389
proc url_DescribeFileSystems_593729(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFileSystems_593728(path: JsonNode; query: JsonNode;
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
  var valid_593841 = query.getOrDefault("FileSystemId")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "FileSystemId", valid_593841
  var valid_593842 = query.getOrDefault("Marker")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "Marker", valid_593842
  var valid_593843 = query.getOrDefault("MaxItems")
  valid_593843 = validateParameter(valid_593843, JInt, required = false, default = nil)
  if valid_593843 != nil:
    section.add "MaxItems", valid_593843
  var valid_593844 = query.getOrDefault("CreationToken")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "CreationToken", valid_593844
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
  var valid_593845 = header.getOrDefault("X-Amz-Signature")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Signature", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Content-Sha256", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Date")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Date", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Credential")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Credential", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Security-Token")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Security-Token", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Algorithm")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Algorithm", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-SignedHeaders", valid_593851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593874: Call_DescribeFileSystems_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ## 
  let valid = call_593874.validator(path, query, header, formData, body)
  let scheme = call_593874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593874.url(scheme.get, call_593874.host, call_593874.base,
                         call_593874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593874, url, valid)

proc call*(call_593945: Call_DescribeFileSystems_593727; FileSystemId: string = "";
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
  var query_593946 = newJObject()
  add(query_593946, "FileSystemId", newJString(FileSystemId))
  add(query_593946, "Marker", newJString(Marker))
  add(query_593946, "MaxItems", newJInt(MaxItems))
  add(query_593946, "CreationToken", newJString(CreationToken))
  result = call_593945.call(nil, query_593946, nil, nil, nil)

var describeFileSystems* = Call_DescribeFileSystems_593727(
    name: "describeFileSystems", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_DescribeFileSystems_593728, base: "/",
    url: url_DescribeFileSystems_593729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMountTarget_594017 = ref object of OpenApiRestCall_593389
proc url_CreateMountTarget_594019(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMountTarget_594018(path: JsonNode; query: JsonNode;
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
  var valid_594020 = header.getOrDefault("X-Amz-Signature")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Signature", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Content-Sha256", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Date")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Date", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Credential")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Credential", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Security-Token")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Security-Token", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Algorithm")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Algorithm", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-SignedHeaders", valid_594026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594028: Call_CreateMountTarget_594017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_594028.validator(path, query, header, formData, body)
  let scheme = call_594028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594028.url(scheme.get, call_594028.host, call_594028.base,
                         call_594028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594028, url, valid)

proc call*(call_594029: Call_CreateMountTarget_594017; body: JsonNode): Recallable =
  ## createMountTarget
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594030 = newJObject()
  if body != nil:
    body_594030 = body
  result = call_594029.call(nil, nil, nil, nil, body_594030)

var createMountTarget* = Call_CreateMountTarget_594017(name: "createMountTarget",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets", validator: validate_CreateMountTarget_594018,
    base: "/", url: url_CreateMountTarget_594019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargets_594000 = ref object of OpenApiRestCall_593389
proc url_DescribeMountTargets_594002(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMountTargets_594001(path: JsonNode; query: JsonNode;
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
  var valid_594003 = query.getOrDefault("FileSystemId")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "FileSystemId", valid_594003
  var valid_594004 = query.getOrDefault("Marker")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "Marker", valid_594004
  var valid_594005 = query.getOrDefault("MaxItems")
  valid_594005 = validateParameter(valid_594005, JInt, required = false, default = nil)
  if valid_594005 != nil:
    section.add "MaxItems", valid_594005
  var valid_594006 = query.getOrDefault("MountTargetId")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "MountTargetId", valid_594006
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
  var valid_594007 = header.getOrDefault("X-Amz-Signature")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Signature", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Content-Sha256", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Date")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Date", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-Credential")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Credential", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-Security-Token")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-Security-Token", valid_594011
  var valid_594012 = header.getOrDefault("X-Amz-Algorithm")
  valid_594012 = validateParameter(valid_594012, JString, required = false,
                                 default = nil)
  if valid_594012 != nil:
    section.add "X-Amz-Algorithm", valid_594012
  var valid_594013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-SignedHeaders", valid_594013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594014: Call_DescribeMountTargets_594000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  let valid = call_594014.validator(path, query, header, formData, body)
  let scheme = call_594014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594014.url(scheme.get, call_594014.host, call_594014.base,
                         call_594014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594014, url, valid)

proc call*(call_594015: Call_DescribeMountTargets_594000;
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
  var query_594016 = newJObject()
  add(query_594016, "FileSystemId", newJString(FileSystemId))
  add(query_594016, "Marker", newJString(Marker))
  add(query_594016, "MaxItems", newJInt(MaxItems))
  add(query_594016, "MountTargetId", newJString(MountTargetId))
  result = call_594015.call(nil, query_594016, nil, nil, nil)

var describeMountTargets* = Call_DescribeMountTargets_594000(
    name: "describeMountTargets", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_DescribeMountTargets_594001, base: "/",
    url: url_DescribeMountTargets_594002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_594031 = ref object of OpenApiRestCall_593389
proc url_CreateTags_594033(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_594032(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594048 = path.getOrDefault("FileSystemId")
  valid_594048 = validateParameter(valid_594048, JString, required = true,
                                 default = nil)
  if valid_594048 != nil:
    section.add "FileSystemId", valid_594048
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
  var valid_594049 = header.getOrDefault("X-Amz-Signature")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Signature", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Content-Sha256", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Credential")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Credential", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Security-Token")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Security-Token", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-SignedHeaders", valid_594055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594057: Call_CreateTags_594031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ## 
  let valid = call_594057.validator(path, query, header, formData, body)
  let scheme = call_594057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594057.url(scheme.get, call_594057.host, call_594057.base,
                         call_594057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594057, url, valid)

proc call*(call_594058: Call_CreateTags_594031; FileSystemId: string; body: JsonNode): Recallable =
  ## createTags
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to modify (String). This operation modifies the tags only, not the file system.
  ##   body: JObject (required)
  var path_594059 = newJObject()
  var body_594060 = newJObject()
  add(path_594059, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_594060 = body
  result = call_594058.call(path_594059, nil, nil, nil, body_594060)

var createTags* = Call_CreateTags_594031(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/create-tags/{FileSystemId}",
                                      validator: validate_CreateTags_594032,
                                      base: "/", url: url_CreateTags_594033,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_594061 = ref object of OpenApiRestCall_593389
proc url_UpdateFileSystem_594063(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFileSystem_594062(path: JsonNode; query: JsonNode;
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
  var valid_594064 = path.getOrDefault("FileSystemId")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = nil)
  if valid_594064 != nil:
    section.add "FileSystemId", valid_594064
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
  var valid_594065 = header.getOrDefault("X-Amz-Signature")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Signature", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Content-Sha256", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Date")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Date", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Security-Token")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Security-Token", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Algorithm")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Algorithm", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-SignedHeaders", valid_594071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594073: Call_UpdateFileSystem_594061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ## 
  let valid = call_594073.validator(path, query, header, formData, body)
  let scheme = call_594073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594073.url(scheme.get, call_594073.host, call_594073.base,
                         call_594073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594073, url, valid)

proc call*(call_594074: Call_UpdateFileSystem_594061; FileSystemId: string;
          body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system that you want to update.
  ##   body: JObject (required)
  var path_594075 = newJObject()
  var body_594076 = newJObject()
  add(path_594075, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_594076 = body
  result = call_594074.call(path_594075, nil, nil, nil, body_594076)

var updateFileSystem* = Call_UpdateFileSystem_594061(name: "updateFileSystem",
    meth: HttpMethod.HttpPut, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_UpdateFileSystem_594062, base: "/",
    url: url_UpdateFileSystem_594063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_594077 = ref object of OpenApiRestCall_593389
proc url_DeleteFileSystem_594079(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFileSystem_594078(path: JsonNode; query: JsonNode;
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
  var valid_594080 = path.getOrDefault("FileSystemId")
  valid_594080 = validateParameter(valid_594080, JString, required = true,
                                 default = nil)
  if valid_594080 != nil:
    section.add "FileSystemId", valid_594080
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
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Content-Sha256", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Date")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Date", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Security-Token")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Security-Token", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Algorithm")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Algorithm", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-SignedHeaders", valid_594087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594088: Call_DeleteFileSystem_594077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ## 
  let valid = call_594088.validator(path, query, header, formData, body)
  let scheme = call_594088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594088.url(scheme.get, call_594088.host, call_594088.base,
                         call_594088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594088, url, valid)

proc call*(call_594089: Call_DeleteFileSystem_594077; FileSystemId: string): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system you want to delete.
  var path_594090 = newJObject()
  add(path_594090, "FileSystemId", newJString(FileSystemId))
  result = call_594089.call(path_594090, nil, nil, nil, nil)

var deleteFileSystem* = Call_DeleteFileSystem_594077(name: "deleteFileSystem",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_DeleteFileSystem_594078, base: "/",
    url: url_DeleteFileSystem_594079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMountTarget_594091 = ref object of OpenApiRestCall_593389
proc url_DeleteMountTarget_594093(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMountTarget_594092(path: JsonNode; query: JsonNode;
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
  var valid_594094 = path.getOrDefault("MountTargetId")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "MountTargetId", valid_594094
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
  var valid_594095 = header.getOrDefault("X-Amz-Signature")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Signature", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Content-Sha256", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Date")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Date", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Security-Token")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Security-Token", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Algorithm")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Algorithm", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-SignedHeaders", valid_594101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594102: Call_DeleteMountTarget_594091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_594102.validator(path, query, header, formData, body)
  let scheme = call_594102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594102.url(scheme.get, call_594102.host, call_594102.base,
                         call_594102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594102, url, valid)

proc call*(call_594103: Call_DeleteMountTarget_594091; MountTargetId: string): Recallable =
  ## deleteMountTarget
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target to delete (String).
  var path_594104 = newJObject()
  add(path_594104, "MountTargetId", newJString(MountTargetId))
  result = call_594103.call(path_594104, nil, nil, nil, nil)

var deleteMountTarget* = Call_DeleteMountTarget_594091(name: "deleteMountTarget",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}",
    validator: validate_DeleteMountTarget_594092, base: "/",
    url: url_DeleteMountTarget_594093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_594105 = ref object of OpenApiRestCall_593389
proc url_DeleteTags_594107(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_594106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594108 = path.getOrDefault("FileSystemId")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = nil)
  if valid_594108 != nil:
    section.add "FileSystemId", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Signature")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Signature", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Date")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Date", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Security-Token")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Security-Token", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Algorithm")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Algorithm", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-SignedHeaders", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_DeleteTags_594105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_DeleteTags_594105; FileSystemId: string; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to delete (String).
  ##   body: JObject (required)
  var path_594119 = newJObject()
  var body_594120 = newJObject()
  add(path_594119, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_594120 = body
  result = call_594118.call(path_594119, nil, nil, nil, body_594120)

var deleteTags* = Call_DeleteTags_594105(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/delete-tags/{FileSystemId}",
                                      validator: validate_DeleteTags_594106,
                                      base: "/", url: url_DeleteTags_594107,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleConfiguration_594135 = ref object of OpenApiRestCall_593389
proc url_PutLifecycleConfiguration_594137(protocol: Scheme; host: string;
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

proc validate_PutLifecycleConfiguration_594136(path: JsonNode; query: JsonNode;
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
  var valid_594138 = path.getOrDefault("FileSystemId")
  valid_594138 = validateParameter(valid_594138, JString, required = true,
                                 default = nil)
  if valid_594138 != nil:
    section.add "FileSystemId", valid_594138
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
  var valid_594139 = header.getOrDefault("X-Amz-Signature")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Signature", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Content-Sha256", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Date")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Date", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Credential")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Credential", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Security-Token")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Security-Token", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Algorithm")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Algorithm", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-SignedHeaders", valid_594145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594147: Call_PutLifecycleConfiguration_594135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ## 
  let valid = call_594147.validator(path, query, header, formData, body)
  let scheme = call_594147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594147.url(scheme.get, call_594147.host, call_594147.base,
                         call_594147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594147, url, valid)

proc call*(call_594148: Call_PutLifecycleConfiguration_594135;
          FileSystemId: string; body: JsonNode): Recallable =
  ## putLifecycleConfiguration
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system for which you are creating the <code>LifecycleConfiguration</code> object (String).
  ##   body: JObject (required)
  var path_594149 = newJObject()
  var body_594150 = newJObject()
  add(path_594149, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_594150 = body
  result = call_594148.call(path_594149, nil, nil, nil, body_594150)

var putLifecycleConfiguration* = Call_PutLifecycleConfiguration_594135(
    name: "putLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_PutLifecycleConfiguration_594136, base: "/",
    url: url_PutLifecycleConfiguration_594137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLifecycleConfiguration_594121 = ref object of OpenApiRestCall_593389
proc url_DescribeLifecycleConfiguration_594123(protocol: Scheme; host: string;
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

proc validate_DescribeLifecycleConfiguration_594122(path: JsonNode;
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
  var valid_594124 = path.getOrDefault("FileSystemId")
  valid_594124 = validateParameter(valid_594124, JString, required = true,
                                 default = nil)
  if valid_594124 != nil:
    section.add "FileSystemId", valid_594124
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
  var valid_594125 = header.getOrDefault("X-Amz-Signature")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Signature", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Content-Sha256", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Date")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Date", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Security-Token")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Security-Token", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Algorithm")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Algorithm", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-SignedHeaders", valid_594131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594132: Call_DescribeLifecycleConfiguration_594121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ## 
  let valid = call_594132.validator(path, query, header, formData, body)
  let scheme = call_594132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594132.url(scheme.get, call_594132.host, call_594132.base,
                         call_594132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594132, url, valid)

proc call*(call_594133: Call_DescribeLifecycleConfiguration_594121;
          FileSystemId: string): Recallable =
  ## describeLifecycleConfiguration
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose <code>LifecycleConfiguration</code> object you want to retrieve (String).
  var path_594134 = newJObject()
  add(path_594134, "FileSystemId", newJString(FileSystemId))
  result = call_594133.call(path_594134, nil, nil, nil, nil)

var describeLifecycleConfiguration* = Call_DescribeLifecycleConfiguration_594121(
    name: "describeLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_DescribeLifecycleConfiguration_594122, base: "/",
    url: url_DescribeLifecycleConfiguration_594123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyMountTargetSecurityGroups_594165 = ref object of OpenApiRestCall_593389
proc url_ModifyMountTargetSecurityGroups_594167(protocol: Scheme; host: string;
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

proc validate_ModifyMountTargetSecurityGroups_594166(path: JsonNode;
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
  var valid_594168 = path.getOrDefault("MountTargetId")
  valid_594168 = validateParameter(valid_594168, JString, required = true,
                                 default = nil)
  if valid_594168 != nil:
    section.add "MountTargetId", valid_594168
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
  var valid_594169 = header.getOrDefault("X-Amz-Signature")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Signature", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Content-Sha256", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Date")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Date", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Credential")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Credential", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Security-Token")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Security-Token", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Algorithm")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Algorithm", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-SignedHeaders", valid_594175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594177: Call_ModifyMountTargetSecurityGroups_594165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_594177.validator(path, query, header, formData, body)
  let scheme = call_594177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594177.url(scheme.get, call_594177.host, call_594177.base,
                         call_594177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594177, url, valid)

proc call*(call_594178: Call_ModifyMountTargetSecurityGroups_594165;
          MountTargetId: string; body: JsonNode): Recallable =
  ## modifyMountTargetSecurityGroups
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to modify.
  ##   body: JObject (required)
  var path_594179 = newJObject()
  var body_594180 = newJObject()
  add(path_594179, "MountTargetId", newJString(MountTargetId))
  if body != nil:
    body_594180 = body
  result = call_594178.call(path_594179, nil, nil, nil, body_594180)

var modifyMountTargetSecurityGroups* = Call_ModifyMountTargetSecurityGroups_594165(
    name: "modifyMountTargetSecurityGroups", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_ModifyMountTargetSecurityGroups_594166, base: "/",
    url: url_ModifyMountTargetSecurityGroups_594167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargetSecurityGroups_594151 = ref object of OpenApiRestCall_593389
proc url_DescribeMountTargetSecurityGroups_594153(protocol: Scheme; host: string;
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

proc validate_DescribeMountTargetSecurityGroups_594152(path: JsonNode;
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
  var valid_594154 = path.getOrDefault("MountTargetId")
  valid_594154 = validateParameter(valid_594154, JString, required = true,
                                 default = nil)
  if valid_594154 != nil:
    section.add "MountTargetId", valid_594154
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
  var valid_594155 = header.getOrDefault("X-Amz-Signature")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Signature", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Content-Sha256", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Date")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Date", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Security-Token")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Security-Token", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Algorithm")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Algorithm", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-SignedHeaders", valid_594161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594162: Call_DescribeMountTargetSecurityGroups_594151;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_594162.validator(path, query, header, formData, body)
  let scheme = call_594162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594162.url(scheme.get, call_594162.host, call_594162.base,
                         call_594162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594162, url, valid)

proc call*(call_594163: Call_DescribeMountTargetSecurityGroups_594151;
          MountTargetId: string): Recallable =
  ## describeMountTargetSecurityGroups
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to retrieve.
  var path_594164 = newJObject()
  add(path_594164, "MountTargetId", newJString(MountTargetId))
  result = call_594163.call(path_594164, nil, nil, nil, nil)

var describeMountTargetSecurityGroups* = Call_DescribeMountTargetSecurityGroups_594151(
    name: "describeMountTargetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_DescribeMountTargetSecurityGroups_594152, base: "/",
    url: url_DescribeMountTargetSecurityGroups_594153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_594181 = ref object of OpenApiRestCall_593389
proc url_DescribeTags_594183(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_594182(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594184 = path.getOrDefault("FileSystemId")
  valid_594184 = validateParameter(valid_594184, JString, required = true,
                                 default = nil)
  if valid_594184 != nil:
    section.add "FileSystemId", valid_594184
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: JInt
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  section = newJObject()
  var valid_594185 = query.getOrDefault("Marker")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "Marker", valid_594185
  var valid_594186 = query.getOrDefault("MaxItems")
  valid_594186 = validateParameter(valid_594186, JInt, required = false, default = nil)
  if valid_594186 != nil:
    section.add "MaxItems", valid_594186
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
  var valid_594187 = header.getOrDefault("X-Amz-Signature")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Signature", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Content-Sha256", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Date")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Date", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Credential")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Credential", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Security-Token")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Security-Token", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Algorithm")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Algorithm", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-SignedHeaders", valid_594193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594194: Call_DescribeTags_594181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ## 
  let valid = call_594194.validator(path, query, header, formData, body)
  let scheme = call_594194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594194.url(scheme.get, call_594194.host, call_594194.base,
                         call_594194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594194, url, valid)

proc call*(call_594195: Call_DescribeTags_594181; FileSystemId: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## describeTags
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ##   Marker: string
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: int
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tag set you want to retrieve.
  var path_594196 = newJObject()
  var query_594197 = newJObject()
  add(query_594197, "Marker", newJString(Marker))
  add(query_594197, "MaxItems", newJInt(MaxItems))
  add(path_594196, "FileSystemId", newJString(FileSystemId))
  result = call_594195.call(path_594196, query_594197, nil, nil, nil)

var describeTags* = Call_DescribeTags_594181(name: "describeTags",
    meth: HttpMethod.HttpGet, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/tags/{FileSystemId}/", validator: validate_DescribeTags_594182,
    base: "/", url: url_DescribeTags_594183, schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
