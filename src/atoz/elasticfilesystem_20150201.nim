
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

  OpenApiRestCall_604389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_604389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_604389): Option[Scheme] {.used.} =
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
  Call_CreateAccessPoint_604986 = ref object of OpenApiRestCall_604389
proc url_CreateAccessPoint_604988(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAccessPoint_604987(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in its own directory and below. To learn more, see <a href="https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html">Mounting a File System Using EFS Access Points</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:CreateAccessPoint</code> action.</p>
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
  var valid_604989 = header.getOrDefault("X-Amz-Signature")
  valid_604989 = validateParameter(valid_604989, JString, required = false,
                                 default = nil)
  if valid_604989 != nil:
    section.add "X-Amz-Signature", valid_604989
  var valid_604990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "X-Amz-Content-Sha256", valid_604990
  var valid_604991 = header.getOrDefault("X-Amz-Date")
  valid_604991 = validateParameter(valid_604991, JString, required = false,
                                 default = nil)
  if valid_604991 != nil:
    section.add "X-Amz-Date", valid_604991
  var valid_604992 = header.getOrDefault("X-Amz-Credential")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Credential", valid_604992
  var valid_604993 = header.getOrDefault("X-Amz-Security-Token")
  valid_604993 = validateParameter(valid_604993, JString, required = false,
                                 default = nil)
  if valid_604993 != nil:
    section.add "X-Amz-Security-Token", valid_604993
  var valid_604994 = header.getOrDefault("X-Amz-Algorithm")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Algorithm", valid_604994
  var valid_604995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "X-Amz-SignedHeaders", valid_604995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604997: Call_CreateAccessPoint_604986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in its own directory and below. To learn more, see <a href="https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html">Mounting a File System Using EFS Access Points</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:CreateAccessPoint</code> action.</p>
  ## 
  let valid = call_604997.validator(path, query, header, formData, body)
  let scheme = call_604997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604997.url(scheme.get, call_604997.host, call_604997.base,
                         call_604997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604997, url, valid)

proc call*(call_604998: Call_CreateAccessPoint_604986; body: JsonNode): Recallable =
  ## createAccessPoint
  ## <p>Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in its own directory and below. To learn more, see <a href="https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html">Mounting a File System Using EFS Access Points</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:CreateAccessPoint</code> action.</p>
  ##   body: JObject (required)
  var body_604999 = newJObject()
  if body != nil:
    body_604999 = body
  result = call_604998.call(nil, nil, nil, nil, body_604999)

var createAccessPoint* = Call_CreateAccessPoint_604986(name: "createAccessPoint",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/access-points", validator: validate_CreateAccessPoint_604987,
    base: "/", url: url_CreateAccessPoint_604988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccessPoints_604727 = ref object of OpenApiRestCall_604389
proc url_DescribeAccessPoints_604729(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAccessPoints_604728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the description of a specific Amazon EFS access point if the <code>AccessPointId</code> is provided. If you provide an EFS <code>FileSystemId</code>, it returns descriptions of all access points for that file system. You can provide either an <code>AccessPointId</code> or a <code>FileSystemId</code> in the request, but not both. </p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FileSystemId: JString
  ##               : (Optional) If you provide a <code>FileSystemId</code>, EFS returns all access points for that file system; mutually exclusive with <code>AccessPointId</code>.
  ##   MaxResults: JInt
  ##             : (Optional) When retrieving all access points for a file system, you can optionally specify the <code>MaxItems</code> parameter to limit the number of objects returned in a response. The default value is 100. 
  ##   AccessPointId: JString
  ##                : (Optional) Specifies an EFS access point to describe in the response; mutually exclusive with <code>FileSystemId</code>.
  ##   NextToken: JString
  ##            :  <code>NextToken</code> is present if the response is paginated. You can use <code>NextMarker</code> in the subsequent request to fetch the next page of access point descriptions.
  section = newJObject()
  var valid_604841 = query.getOrDefault("FileSystemId")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "FileSystemId", valid_604841
  var valid_604842 = query.getOrDefault("MaxResults")
  valid_604842 = validateParameter(valid_604842, JInt, required = false, default = nil)
  if valid_604842 != nil:
    section.add "MaxResults", valid_604842
  var valid_604843 = query.getOrDefault("AccessPointId")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "AccessPointId", valid_604843
  var valid_604844 = query.getOrDefault("NextToken")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "NextToken", valid_604844
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
  var valid_604845 = header.getOrDefault("X-Amz-Signature")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Signature", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Content-Sha256", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Date")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Date", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-Credential")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-Credential", valid_604848
  var valid_604849 = header.getOrDefault("X-Amz-Security-Token")
  valid_604849 = validateParameter(valid_604849, JString, required = false,
                                 default = nil)
  if valid_604849 != nil:
    section.add "X-Amz-Security-Token", valid_604849
  var valid_604850 = header.getOrDefault("X-Amz-Algorithm")
  valid_604850 = validateParameter(valid_604850, JString, required = false,
                                 default = nil)
  if valid_604850 != nil:
    section.add "X-Amz-Algorithm", valid_604850
  var valid_604851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604851 = validateParameter(valid_604851, JString, required = false,
                                 default = nil)
  if valid_604851 != nil:
    section.add "X-Amz-SignedHeaders", valid_604851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604874: Call_DescribeAccessPoints_604727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of a specific Amazon EFS access point if the <code>AccessPointId</code> is provided. If you provide an EFS <code>FileSystemId</code>, it returns descriptions of all access points for that file system. You can provide either an <code>AccessPointId</code> or a <code>FileSystemId</code> in the request, but not both. </p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ## 
  let valid = call_604874.validator(path, query, header, formData, body)
  let scheme = call_604874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604874.url(scheme.get, call_604874.host, call_604874.base,
                         call_604874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604874, url, valid)

proc call*(call_604945: Call_DescribeAccessPoints_604727;
          FileSystemId: string = ""; MaxResults: int = 0; AccessPointId: string = "";
          NextToken: string = ""): Recallable =
  ## describeAccessPoints
  ## <p>Returns the description of a specific Amazon EFS access point if the <code>AccessPointId</code> is provided. If you provide an EFS <code>FileSystemId</code>, it returns descriptions of all access points for that file system. You can provide either an <code>AccessPointId</code> or a <code>FileSystemId</code> in the request, but not both. </p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ##   FileSystemId: string
  ##               : (Optional) If you provide a <code>FileSystemId</code>, EFS returns all access points for that file system; mutually exclusive with <code>AccessPointId</code>.
  ##   MaxResults: int
  ##             : (Optional) When retrieving all access points for a file system, you can optionally specify the <code>MaxItems</code> parameter to limit the number of objects returned in a response. The default value is 100. 
  ##   AccessPointId: string
  ##                : (Optional) Specifies an EFS access point to describe in the response; mutually exclusive with <code>FileSystemId</code>.
  ##   NextToken: string
  ##            :  <code>NextToken</code> is present if the response is paginated. You can use <code>NextMarker</code> in the subsequent request to fetch the next page of access point descriptions.
  var query_604946 = newJObject()
  add(query_604946, "FileSystemId", newJString(FileSystemId))
  add(query_604946, "MaxResults", newJInt(MaxResults))
  add(query_604946, "AccessPointId", newJString(AccessPointId))
  add(query_604946, "NextToken", newJString(NextToken))
  result = call_604945.call(nil, query_604946, nil, nil, nil)

var describeAccessPoints* = Call_DescribeAccessPoints_604727(
    name: "describeAccessPoints", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/access-points",
    validator: validate_DescribeAccessPoints_604728, base: "/",
    url: url_DescribeAccessPoints_604729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystem_605017 = ref object of OpenApiRestCall_604389
proc url_CreateFileSystem_605019(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFileSystem_605018(path: JsonNode; query: JsonNode;
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
  var valid_605020 = header.getOrDefault("X-Amz-Signature")
  valid_605020 = validateParameter(valid_605020, JString, required = false,
                                 default = nil)
  if valid_605020 != nil:
    section.add "X-Amz-Signature", valid_605020
  var valid_605021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605021 = validateParameter(valid_605021, JString, required = false,
                                 default = nil)
  if valid_605021 != nil:
    section.add "X-Amz-Content-Sha256", valid_605021
  var valid_605022 = header.getOrDefault("X-Amz-Date")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "X-Amz-Date", valid_605022
  var valid_605023 = header.getOrDefault("X-Amz-Credential")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "X-Amz-Credential", valid_605023
  var valid_605024 = header.getOrDefault("X-Amz-Security-Token")
  valid_605024 = validateParameter(valid_605024, JString, required = false,
                                 default = nil)
  if valid_605024 != nil:
    section.add "X-Amz-Security-Token", valid_605024
  var valid_605025 = header.getOrDefault("X-Amz-Algorithm")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-Algorithm", valid_605025
  var valid_605026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605026 = validateParameter(valid_605026, JString, required = false,
                                 default = nil)
  if valid_605026 != nil:
    section.add "X-Amz-SignedHeaders", valid_605026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605028: Call_CreateFileSystem_605017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ## 
  let valid = call_605028.validator(path, query, header, formData, body)
  let scheme = call_605028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605028.url(scheme.get, call_605028.host, call_605028.base,
                         call_605028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605028, url, valid)

proc call*(call_605029: Call_CreateFileSystem_605017; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ##   body: JObject (required)
  var body_605030 = newJObject()
  if body != nil:
    body_605030 = body
  result = call_605029.call(nil, nil, nil, nil, body_605030)

var createFileSystem* = Call_CreateFileSystem_605017(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems", validator: validate_CreateFileSystem_605018,
    base: "/", url: url_CreateFileSystem_605019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_605000 = ref object of OpenApiRestCall_604389
proc url_DescribeFileSystems_605002(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFileSystems_605001(path: JsonNode; query: JsonNode;
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
  ##           : (Optional) Specifies the maximum number of file systems to return in the response (integer). This number is automatically set to 100. The response is paginated at 100 per page if you have more than 100 file systems. 
  ##   CreationToken: JString
  ##                : (Optional) Restricts the list to the file system with this creation token (String). You specify a creation token when you create an Amazon EFS file system.
  section = newJObject()
  var valid_605003 = query.getOrDefault("FileSystemId")
  valid_605003 = validateParameter(valid_605003, JString, required = false,
                                 default = nil)
  if valid_605003 != nil:
    section.add "FileSystemId", valid_605003
  var valid_605004 = query.getOrDefault("Marker")
  valid_605004 = validateParameter(valid_605004, JString, required = false,
                                 default = nil)
  if valid_605004 != nil:
    section.add "Marker", valid_605004
  var valid_605005 = query.getOrDefault("MaxItems")
  valid_605005 = validateParameter(valid_605005, JInt, required = false, default = nil)
  if valid_605005 != nil:
    section.add "MaxItems", valid_605005
  var valid_605006 = query.getOrDefault("CreationToken")
  valid_605006 = validateParameter(valid_605006, JString, required = false,
                                 default = nil)
  if valid_605006 != nil:
    section.add "CreationToken", valid_605006
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
  var valid_605007 = header.getOrDefault("X-Amz-Signature")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "X-Amz-Signature", valid_605007
  var valid_605008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605008 = validateParameter(valid_605008, JString, required = false,
                                 default = nil)
  if valid_605008 != nil:
    section.add "X-Amz-Content-Sha256", valid_605008
  var valid_605009 = header.getOrDefault("X-Amz-Date")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "X-Amz-Date", valid_605009
  var valid_605010 = header.getOrDefault("X-Amz-Credential")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "X-Amz-Credential", valid_605010
  var valid_605011 = header.getOrDefault("X-Amz-Security-Token")
  valid_605011 = validateParameter(valid_605011, JString, required = false,
                                 default = nil)
  if valid_605011 != nil:
    section.add "X-Amz-Security-Token", valid_605011
  var valid_605012 = header.getOrDefault("X-Amz-Algorithm")
  valid_605012 = validateParameter(valid_605012, JString, required = false,
                                 default = nil)
  if valid_605012 != nil:
    section.add "X-Amz-Algorithm", valid_605012
  var valid_605013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605013 = validateParameter(valid_605013, JString, required = false,
                                 default = nil)
  if valid_605013 != nil:
    section.add "X-Amz-SignedHeaders", valid_605013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605014: Call_DescribeFileSystems_605000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ## 
  let valid = call_605014.validator(path, query, header, formData, body)
  let scheme = call_605014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605014.url(scheme.get, call_605014.host, call_605014.base,
                         call_605014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605014, url, valid)

proc call*(call_605015: Call_DescribeFileSystems_605000; FileSystemId: string = "";
          Marker: string = ""; MaxItems: int = 0; CreationToken: string = ""): Recallable =
  ## describeFileSystems
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ##   FileSystemId: string
  ##               : (Optional) ID of the file system whose description you want to retrieve (String).
  ##   Marker: string
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeFileSystems</code> operation (String). If present, specifies to continue the list from where the returning call had left off. 
  ##   MaxItems: int
  ##           : (Optional) Specifies the maximum number of file systems to return in the response (integer). This number is automatically set to 100. The response is paginated at 100 per page if you have more than 100 file systems. 
  ##   CreationToken: string
  ##                : (Optional) Restricts the list to the file system with this creation token (String). You specify a creation token when you create an Amazon EFS file system.
  var query_605016 = newJObject()
  add(query_605016, "FileSystemId", newJString(FileSystemId))
  add(query_605016, "Marker", newJString(Marker))
  add(query_605016, "MaxItems", newJInt(MaxItems))
  add(query_605016, "CreationToken", newJString(CreationToken))
  result = call_605015.call(nil, query_605016, nil, nil, nil)

var describeFileSystems* = Call_DescribeFileSystems_605000(
    name: "describeFileSystems", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_DescribeFileSystems_605001, base: "/",
    url: url_DescribeFileSystems_605002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMountTarget_605049 = ref object of OpenApiRestCall_604389
proc url_CreateMountTarget_605051(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMountTarget_605050(path: JsonNode; query: JsonNode;
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
  var valid_605052 = header.getOrDefault("X-Amz-Signature")
  valid_605052 = validateParameter(valid_605052, JString, required = false,
                                 default = nil)
  if valid_605052 != nil:
    section.add "X-Amz-Signature", valid_605052
  var valid_605053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605053 = validateParameter(valid_605053, JString, required = false,
                                 default = nil)
  if valid_605053 != nil:
    section.add "X-Amz-Content-Sha256", valid_605053
  var valid_605054 = header.getOrDefault("X-Amz-Date")
  valid_605054 = validateParameter(valid_605054, JString, required = false,
                                 default = nil)
  if valid_605054 != nil:
    section.add "X-Amz-Date", valid_605054
  var valid_605055 = header.getOrDefault("X-Amz-Credential")
  valid_605055 = validateParameter(valid_605055, JString, required = false,
                                 default = nil)
  if valid_605055 != nil:
    section.add "X-Amz-Credential", valid_605055
  var valid_605056 = header.getOrDefault("X-Amz-Security-Token")
  valid_605056 = validateParameter(valid_605056, JString, required = false,
                                 default = nil)
  if valid_605056 != nil:
    section.add "X-Amz-Security-Token", valid_605056
  var valid_605057 = header.getOrDefault("X-Amz-Algorithm")
  valid_605057 = validateParameter(valid_605057, JString, required = false,
                                 default = nil)
  if valid_605057 != nil:
    section.add "X-Amz-Algorithm", valid_605057
  var valid_605058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605058 = validateParameter(valid_605058, JString, required = false,
                                 default = nil)
  if valid_605058 != nil:
    section.add "X-Amz-SignedHeaders", valid_605058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605060: Call_CreateMountTarget_605049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_605060.validator(path, query, header, formData, body)
  let scheme = call_605060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605060.url(scheme.get, call_605060.host, call_605060.base,
                         call_605060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605060, url, valid)

proc call*(call_605061: Call_CreateMountTarget_605049; body: JsonNode): Recallable =
  ## createMountTarget
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_605062 = newJObject()
  if body != nil:
    body_605062 = body
  result = call_605061.call(nil, nil, nil, nil, body_605062)

var createMountTarget* = Call_CreateMountTarget_605049(name: "createMountTarget",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets", validator: validate_CreateMountTarget_605050,
    base: "/", url: url_CreateMountTarget_605051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargets_605031 = ref object of OpenApiRestCall_604389
proc url_DescribeMountTargets_605033(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMountTargets_605032(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FileSystemId: JString
  ##               : (Optional) ID of the file system whose mount targets you want to list (String). It must be included in your request if an <code>AccessPointId</code> or <code>MountTargetId</code> is not included. Accepts either a file system ID or ARN as input.
  ##   Marker: JString
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeMountTargets</code> operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  ##   MaxItems: JInt
  ##           : (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 100 per page if you have more than 100 mount targets.
  ##   AccessPointId: JString
  ##                : (Optional) The ID of the access point whose mount targets that you want to list. It must be included in your request if a <code>FileSystemId</code> or <code>MountTargetId</code> is not included in your request. Accepts either an access point ID or ARN as input.
  ##   MountTargetId: JString
  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included. Accepts either a mount target ID or ARN as input.
  section = newJObject()
  var valid_605034 = query.getOrDefault("FileSystemId")
  valid_605034 = validateParameter(valid_605034, JString, required = false,
                                 default = nil)
  if valid_605034 != nil:
    section.add "FileSystemId", valid_605034
  var valid_605035 = query.getOrDefault("Marker")
  valid_605035 = validateParameter(valid_605035, JString, required = false,
                                 default = nil)
  if valid_605035 != nil:
    section.add "Marker", valid_605035
  var valid_605036 = query.getOrDefault("MaxItems")
  valid_605036 = validateParameter(valid_605036, JInt, required = false, default = nil)
  if valid_605036 != nil:
    section.add "MaxItems", valid_605036
  var valid_605037 = query.getOrDefault("AccessPointId")
  valid_605037 = validateParameter(valid_605037, JString, required = false,
                                 default = nil)
  if valid_605037 != nil:
    section.add "AccessPointId", valid_605037
  var valid_605038 = query.getOrDefault("MountTargetId")
  valid_605038 = validateParameter(valid_605038, JString, required = false,
                                 default = nil)
  if valid_605038 != nil:
    section.add "MountTargetId", valid_605038
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
  var valid_605039 = header.getOrDefault("X-Amz-Signature")
  valid_605039 = validateParameter(valid_605039, JString, required = false,
                                 default = nil)
  if valid_605039 != nil:
    section.add "X-Amz-Signature", valid_605039
  var valid_605040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "X-Amz-Content-Sha256", valid_605040
  var valid_605041 = header.getOrDefault("X-Amz-Date")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "X-Amz-Date", valid_605041
  var valid_605042 = header.getOrDefault("X-Amz-Credential")
  valid_605042 = validateParameter(valid_605042, JString, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "X-Amz-Credential", valid_605042
  var valid_605043 = header.getOrDefault("X-Amz-Security-Token")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "X-Amz-Security-Token", valid_605043
  var valid_605044 = header.getOrDefault("X-Amz-Algorithm")
  valid_605044 = validateParameter(valid_605044, JString, required = false,
                                 default = nil)
  if valid_605044 != nil:
    section.add "X-Amz-Algorithm", valid_605044
  var valid_605045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605045 = validateParameter(valid_605045, JString, required = false,
                                 default = nil)
  if valid_605045 != nil:
    section.add "X-Amz-SignedHeaders", valid_605045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605046: Call_DescribeMountTargets_605031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  let valid = call_605046.validator(path, query, header, formData, body)
  let scheme = call_605046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605046.url(scheme.get, call_605046.host, call_605046.base,
                         call_605046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605046, url, valid)

proc call*(call_605047: Call_DescribeMountTargets_605031;
          FileSystemId: string = ""; Marker: string = ""; MaxItems: int = 0;
          AccessPointId: string = ""; MountTargetId: string = ""): Recallable =
  ## describeMountTargets
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ##   FileSystemId: string
  ##               : (Optional) ID of the file system whose mount targets you want to list (String). It must be included in your request if an <code>AccessPointId</code> or <code>MountTargetId</code> is not included. Accepts either a file system ID or ARN as input.
  ##   Marker: string
  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeMountTargets</code> operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  ##   MaxItems: int
  ##           : (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 100 per page if you have more than 100 mount targets.
  ##   AccessPointId: string
  ##                : (Optional) The ID of the access point whose mount targets that you want to list. It must be included in your request if a <code>FileSystemId</code> or <code>MountTargetId</code> is not included in your request. Accepts either an access point ID or ARN as input.
  ##   MountTargetId: string
  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included. Accepts either a mount target ID or ARN as input.
  var query_605048 = newJObject()
  add(query_605048, "FileSystemId", newJString(FileSystemId))
  add(query_605048, "Marker", newJString(Marker))
  add(query_605048, "MaxItems", newJInt(MaxItems))
  add(query_605048, "AccessPointId", newJString(AccessPointId))
  add(query_605048, "MountTargetId", newJString(MountTargetId))
  result = call_605047.call(nil, query_605048, nil, nil, nil)

var describeMountTargets* = Call_DescribeMountTargets_605031(
    name: "describeMountTargets", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_DescribeMountTargets_605032, base: "/",
    url: url_DescribeMountTargets_605033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_605063 = ref object of OpenApiRestCall_604389
proc url_CreateTags_605065(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_605064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605080 = path.getOrDefault("FileSystemId")
  valid_605080 = validateParameter(valid_605080, JString, required = true,
                                 default = nil)
  if valid_605080 != nil:
    section.add "FileSystemId", valid_605080
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
  var valid_605081 = header.getOrDefault("X-Amz-Signature")
  valid_605081 = validateParameter(valid_605081, JString, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "X-Amz-Signature", valid_605081
  var valid_605082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605082 = validateParameter(valid_605082, JString, required = false,
                                 default = nil)
  if valid_605082 != nil:
    section.add "X-Amz-Content-Sha256", valid_605082
  var valid_605083 = header.getOrDefault("X-Amz-Date")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "X-Amz-Date", valid_605083
  var valid_605084 = header.getOrDefault("X-Amz-Credential")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "X-Amz-Credential", valid_605084
  var valid_605085 = header.getOrDefault("X-Amz-Security-Token")
  valid_605085 = validateParameter(valid_605085, JString, required = false,
                                 default = nil)
  if valid_605085 != nil:
    section.add "X-Amz-Security-Token", valid_605085
  var valid_605086 = header.getOrDefault("X-Amz-Algorithm")
  valid_605086 = validateParameter(valid_605086, JString, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "X-Amz-Algorithm", valid_605086
  var valid_605087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605087 = validateParameter(valid_605087, JString, required = false,
                                 default = nil)
  if valid_605087 != nil:
    section.add "X-Amz-SignedHeaders", valid_605087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605089: Call_CreateTags_605063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ## 
  let valid = call_605089.validator(path, query, header, formData, body)
  let scheme = call_605089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605089.url(scheme.get, call_605089.host, call_605089.base,
                         call_605089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605089, url, valid)

proc call*(call_605090: Call_CreateTags_605063; FileSystemId: string; body: JsonNode): Recallable =
  ## createTags
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to modify (String). This operation modifies the tags only, not the file system.
  ##   body: JObject (required)
  var path_605091 = newJObject()
  var body_605092 = newJObject()
  add(path_605091, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_605092 = body
  result = call_605090.call(path_605091, nil, nil, nil, body_605092)

var createTags* = Call_CreateTags_605063(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/create-tags/{FileSystemId}",
                                      validator: validate_CreateTags_605064,
                                      base: "/", url: url_CreateTags_605065,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPoint_605093 = ref object of OpenApiRestCall_604389
proc url_DeleteAccessPoint_605095(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccessPointId" in path, "`AccessPointId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/access-points/"),
               (kind: VariableSegment, value: "AccessPointId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPoint_605094(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified access point. After deletion is complete, new clients can no longer connect to the access points. Clients connected to the access point at the time of deletion will continue to function until they terminate their connection.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteAccessPoint</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccessPointId: JString (required)
  ##                : The ID of the access point that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccessPointId` field"
  var valid_605096 = path.getOrDefault("AccessPointId")
  valid_605096 = validateParameter(valid_605096, JString, required = true,
                                 default = nil)
  if valid_605096 != nil:
    section.add "AccessPointId", valid_605096
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
  var valid_605097 = header.getOrDefault("X-Amz-Signature")
  valid_605097 = validateParameter(valid_605097, JString, required = false,
                                 default = nil)
  if valid_605097 != nil:
    section.add "X-Amz-Signature", valid_605097
  var valid_605098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "X-Amz-Content-Sha256", valid_605098
  var valid_605099 = header.getOrDefault("X-Amz-Date")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "X-Amz-Date", valid_605099
  var valid_605100 = header.getOrDefault("X-Amz-Credential")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "X-Amz-Credential", valid_605100
  var valid_605101 = header.getOrDefault("X-Amz-Security-Token")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "X-Amz-Security-Token", valid_605101
  var valid_605102 = header.getOrDefault("X-Amz-Algorithm")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "X-Amz-Algorithm", valid_605102
  var valid_605103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605103 = validateParameter(valid_605103, JString, required = false,
                                 default = nil)
  if valid_605103 != nil:
    section.add "X-Amz-SignedHeaders", valid_605103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605104: Call_DeleteAccessPoint_605093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified access point. After deletion is complete, new clients can no longer connect to the access points. Clients connected to the access point at the time of deletion will continue to function until they terminate their connection.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteAccessPoint</code> action.</p>
  ## 
  let valid = call_605104.validator(path, query, header, formData, body)
  let scheme = call_605104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605104.url(scheme.get, call_605104.host, call_605104.base,
                         call_605104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605104, url, valid)

proc call*(call_605105: Call_DeleteAccessPoint_605093; AccessPointId: string): Recallable =
  ## deleteAccessPoint
  ## <p>Deletes the specified access point. After deletion is complete, new clients can no longer connect to the access points. Clients connected to the access point at the time of deletion will continue to function until they terminate their connection.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteAccessPoint</code> action.</p>
  ##   AccessPointId: string (required)
  ##                : The ID of the access point that you want to delete.
  var path_605106 = newJObject()
  add(path_605106, "AccessPointId", newJString(AccessPointId))
  result = call_605105.call(path_605106, nil, nil, nil, nil)

var deleteAccessPoint* = Call_DeleteAccessPoint_605093(name: "deleteAccessPoint",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/access-points/{AccessPointId}",
    validator: validate_DeleteAccessPoint_605094, base: "/",
    url: url_DeleteAccessPoint_605095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_605107 = ref object of OpenApiRestCall_604389
proc url_UpdateFileSystem_605109(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFileSystem_605108(path: JsonNode; query: JsonNode;
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
  var valid_605110 = path.getOrDefault("FileSystemId")
  valid_605110 = validateParameter(valid_605110, JString, required = true,
                                 default = nil)
  if valid_605110 != nil:
    section.add "FileSystemId", valid_605110
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
  var valid_605111 = header.getOrDefault("X-Amz-Signature")
  valid_605111 = validateParameter(valid_605111, JString, required = false,
                                 default = nil)
  if valid_605111 != nil:
    section.add "X-Amz-Signature", valid_605111
  var valid_605112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605112 = validateParameter(valid_605112, JString, required = false,
                                 default = nil)
  if valid_605112 != nil:
    section.add "X-Amz-Content-Sha256", valid_605112
  var valid_605113 = header.getOrDefault("X-Amz-Date")
  valid_605113 = validateParameter(valid_605113, JString, required = false,
                                 default = nil)
  if valid_605113 != nil:
    section.add "X-Amz-Date", valid_605113
  var valid_605114 = header.getOrDefault("X-Amz-Credential")
  valid_605114 = validateParameter(valid_605114, JString, required = false,
                                 default = nil)
  if valid_605114 != nil:
    section.add "X-Amz-Credential", valid_605114
  var valid_605115 = header.getOrDefault("X-Amz-Security-Token")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "X-Amz-Security-Token", valid_605115
  var valid_605116 = header.getOrDefault("X-Amz-Algorithm")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Algorithm", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-SignedHeaders", valid_605117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605119: Call_UpdateFileSystem_605107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ## 
  let valid = call_605119.validator(path, query, header, formData, body)
  let scheme = call_605119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605119.url(scheme.get, call_605119.host, call_605119.base,
                         call_605119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605119, url, valid)

proc call*(call_605120: Call_UpdateFileSystem_605107; FileSystemId: string;
          body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system that you want to update.
  ##   body: JObject (required)
  var path_605121 = newJObject()
  var body_605122 = newJObject()
  add(path_605121, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_605122 = body
  result = call_605120.call(path_605121, nil, nil, nil, body_605122)

var updateFileSystem* = Call_UpdateFileSystem_605107(name: "updateFileSystem",
    meth: HttpMethod.HttpPut, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_UpdateFileSystem_605108, base: "/",
    url: url_UpdateFileSystem_605109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_605123 = ref object of OpenApiRestCall_604389
proc url_DeleteFileSystem_605125(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFileSystem_605124(path: JsonNode; query: JsonNode;
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
  var valid_605126 = path.getOrDefault("FileSystemId")
  valid_605126 = validateParameter(valid_605126, JString, required = true,
                                 default = nil)
  if valid_605126 != nil:
    section.add "FileSystemId", valid_605126
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
  var valid_605127 = header.getOrDefault("X-Amz-Signature")
  valid_605127 = validateParameter(valid_605127, JString, required = false,
                                 default = nil)
  if valid_605127 != nil:
    section.add "X-Amz-Signature", valid_605127
  var valid_605128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "X-Amz-Content-Sha256", valid_605128
  var valid_605129 = header.getOrDefault("X-Amz-Date")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "X-Amz-Date", valid_605129
  var valid_605130 = header.getOrDefault("X-Amz-Credential")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-Credential", valid_605130
  var valid_605131 = header.getOrDefault("X-Amz-Security-Token")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "X-Amz-Security-Token", valid_605131
  var valid_605132 = header.getOrDefault("X-Amz-Algorithm")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "X-Amz-Algorithm", valid_605132
  var valid_605133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "X-Amz-SignedHeaders", valid_605133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605134: Call_DeleteFileSystem_605123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ## 
  let valid = call_605134.validator(path, query, header, formData, body)
  let scheme = call_605134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605134.url(scheme.get, call_605134.host, call_605134.base,
                         call_605134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605134, url, valid)

proc call*(call_605135: Call_DeleteFileSystem_605123; FileSystemId: string): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system you want to delete.
  var path_605136 = newJObject()
  add(path_605136, "FileSystemId", newJString(FileSystemId))
  result = call_605135.call(path_605136, nil, nil, nil, nil)

var deleteFileSystem* = Call_DeleteFileSystem_605123(name: "deleteFileSystem",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_DeleteFileSystem_605124, base: "/",
    url: url_DeleteFileSystem_605125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFileSystemPolicy_605151 = ref object of OpenApiRestCall_604389
proc url_PutFileSystemPolicy_605153(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFileSystemPolicy_605152(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Applies an Amazon EFS <code>FileSystemPolicy</code> to an Amazon EFS file system. A file system policy is an IAM resource-based policy and can contain multiple policy statements. A file system always has exactly one file system policy, which can be the default policy or an explicit policy set or updated using this API operation. When an explicit policy is set, it overrides the default policy. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>. </p> <p>This operation requires permissions for the <code>elasticfilesystem:PutFileSystemPolicy</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : The ID of the EFS file system that you want to create or update the <code>FileSystemPolicy</code> for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_605154 = path.getOrDefault("FileSystemId")
  valid_605154 = validateParameter(valid_605154, JString, required = true,
                                 default = nil)
  if valid_605154 != nil:
    section.add "FileSystemId", valid_605154
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
  var valid_605155 = header.getOrDefault("X-Amz-Signature")
  valid_605155 = validateParameter(valid_605155, JString, required = false,
                                 default = nil)
  if valid_605155 != nil:
    section.add "X-Amz-Signature", valid_605155
  var valid_605156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605156 = validateParameter(valid_605156, JString, required = false,
                                 default = nil)
  if valid_605156 != nil:
    section.add "X-Amz-Content-Sha256", valid_605156
  var valid_605157 = header.getOrDefault("X-Amz-Date")
  valid_605157 = validateParameter(valid_605157, JString, required = false,
                                 default = nil)
  if valid_605157 != nil:
    section.add "X-Amz-Date", valid_605157
  var valid_605158 = header.getOrDefault("X-Amz-Credential")
  valid_605158 = validateParameter(valid_605158, JString, required = false,
                                 default = nil)
  if valid_605158 != nil:
    section.add "X-Amz-Credential", valid_605158
  var valid_605159 = header.getOrDefault("X-Amz-Security-Token")
  valid_605159 = validateParameter(valid_605159, JString, required = false,
                                 default = nil)
  if valid_605159 != nil:
    section.add "X-Amz-Security-Token", valid_605159
  var valid_605160 = header.getOrDefault("X-Amz-Algorithm")
  valid_605160 = validateParameter(valid_605160, JString, required = false,
                                 default = nil)
  if valid_605160 != nil:
    section.add "X-Amz-Algorithm", valid_605160
  var valid_605161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605161 = validateParameter(valid_605161, JString, required = false,
                                 default = nil)
  if valid_605161 != nil:
    section.add "X-Amz-SignedHeaders", valid_605161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605163: Call_PutFileSystemPolicy_605151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies an Amazon EFS <code>FileSystemPolicy</code> to an Amazon EFS file system. A file system policy is an IAM resource-based policy and can contain multiple policy statements. A file system always has exactly one file system policy, which can be the default policy or an explicit policy set or updated using this API operation. When an explicit policy is set, it overrides the default policy. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>. </p> <p>This operation requires permissions for the <code>elasticfilesystem:PutFileSystemPolicy</code> action.</p>
  ## 
  let valid = call_605163.validator(path, query, header, formData, body)
  let scheme = call_605163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605163.url(scheme.get, call_605163.host, call_605163.base,
                         call_605163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605163, url, valid)

proc call*(call_605164: Call_PutFileSystemPolicy_605151; FileSystemId: string;
          body: JsonNode): Recallable =
  ## putFileSystemPolicy
  ## <p>Applies an Amazon EFS <code>FileSystemPolicy</code> to an Amazon EFS file system. A file system policy is an IAM resource-based policy and can contain multiple policy statements. A file system always has exactly one file system policy, which can be the default policy or an explicit policy set or updated using this API operation. When an explicit policy is set, it overrides the default policy. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>. </p> <p>This operation requires permissions for the <code>elasticfilesystem:PutFileSystemPolicy</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the EFS file system that you want to create or update the <code>FileSystemPolicy</code> for.
  ##   body: JObject (required)
  var path_605165 = newJObject()
  var body_605166 = newJObject()
  add(path_605165, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_605166 = body
  result = call_605164.call(path_605165, nil, nil, nil, body_605166)

var putFileSystemPolicy* = Call_PutFileSystemPolicy_605151(
    name: "putFileSystemPolicy", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/policy",
    validator: validate_PutFileSystemPolicy_605152, base: "/",
    url: url_PutFileSystemPolicy_605153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystemPolicy_605137 = ref object of OpenApiRestCall_604389
proc url_DescribeFileSystemPolicy_605139(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFileSystemPolicy_605138(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the <code>FileSystemPolicy</code> for the specified EFS file system.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystemPolicy</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : Specifies which EFS file system to retrieve the <code>FileSystemPolicy</code> for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_605140 = path.getOrDefault("FileSystemId")
  valid_605140 = validateParameter(valid_605140, JString, required = true,
                                 default = nil)
  if valid_605140 != nil:
    section.add "FileSystemId", valid_605140
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
  var valid_605141 = header.getOrDefault("X-Amz-Signature")
  valid_605141 = validateParameter(valid_605141, JString, required = false,
                                 default = nil)
  if valid_605141 != nil:
    section.add "X-Amz-Signature", valid_605141
  var valid_605142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605142 = validateParameter(valid_605142, JString, required = false,
                                 default = nil)
  if valid_605142 != nil:
    section.add "X-Amz-Content-Sha256", valid_605142
  var valid_605143 = header.getOrDefault("X-Amz-Date")
  valid_605143 = validateParameter(valid_605143, JString, required = false,
                                 default = nil)
  if valid_605143 != nil:
    section.add "X-Amz-Date", valid_605143
  var valid_605144 = header.getOrDefault("X-Amz-Credential")
  valid_605144 = validateParameter(valid_605144, JString, required = false,
                                 default = nil)
  if valid_605144 != nil:
    section.add "X-Amz-Credential", valid_605144
  var valid_605145 = header.getOrDefault("X-Amz-Security-Token")
  valid_605145 = validateParameter(valid_605145, JString, required = false,
                                 default = nil)
  if valid_605145 != nil:
    section.add "X-Amz-Security-Token", valid_605145
  var valid_605146 = header.getOrDefault("X-Amz-Algorithm")
  valid_605146 = validateParameter(valid_605146, JString, required = false,
                                 default = nil)
  if valid_605146 != nil:
    section.add "X-Amz-Algorithm", valid_605146
  var valid_605147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605147 = validateParameter(valid_605147, JString, required = false,
                                 default = nil)
  if valid_605147 != nil:
    section.add "X-Amz-SignedHeaders", valid_605147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605148: Call_DescribeFileSystemPolicy_605137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <code>FileSystemPolicy</code> for the specified EFS file system.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystemPolicy</code> action.</p>
  ## 
  let valid = call_605148.validator(path, query, header, formData, body)
  let scheme = call_605148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605148.url(scheme.get, call_605148.host, call_605148.base,
                         call_605148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605148, url, valid)

proc call*(call_605149: Call_DescribeFileSystemPolicy_605137; FileSystemId: string): Recallable =
  ## describeFileSystemPolicy
  ## <p>Returns the <code>FileSystemPolicy</code> for the specified EFS file system.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystemPolicy</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : Specifies which EFS file system to retrieve the <code>FileSystemPolicy</code> for.
  var path_605150 = newJObject()
  add(path_605150, "FileSystemId", newJString(FileSystemId))
  result = call_605149.call(path_605150, nil, nil, nil, nil)

var describeFileSystemPolicy* = Call_DescribeFileSystemPolicy_605137(
    name: "describeFileSystemPolicy", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/policy",
    validator: validate_DescribeFileSystemPolicy_605138, base: "/",
    url: url_DescribeFileSystemPolicy_605139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystemPolicy_605167 = ref object of OpenApiRestCall_604389
proc url_DeleteFileSystemPolicy_605169(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFileSystemPolicy_605168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the <code>FileSystemPolicy</code> for the specified file system. The default <code>FileSystemPolicy</code> goes into effect once the existing policy is deleted. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystemPolicy</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FileSystemId: JString (required)
  ##               : Specifies the EFS file system for which to delete the <code>FileSystemPolicy</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FileSystemId` field"
  var valid_605170 = path.getOrDefault("FileSystemId")
  valid_605170 = validateParameter(valid_605170, JString, required = true,
                                 default = nil)
  if valid_605170 != nil:
    section.add "FileSystemId", valid_605170
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
  var valid_605171 = header.getOrDefault("X-Amz-Signature")
  valid_605171 = validateParameter(valid_605171, JString, required = false,
                                 default = nil)
  if valid_605171 != nil:
    section.add "X-Amz-Signature", valid_605171
  var valid_605172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605172 = validateParameter(valid_605172, JString, required = false,
                                 default = nil)
  if valid_605172 != nil:
    section.add "X-Amz-Content-Sha256", valid_605172
  var valid_605173 = header.getOrDefault("X-Amz-Date")
  valid_605173 = validateParameter(valid_605173, JString, required = false,
                                 default = nil)
  if valid_605173 != nil:
    section.add "X-Amz-Date", valid_605173
  var valid_605174 = header.getOrDefault("X-Amz-Credential")
  valid_605174 = validateParameter(valid_605174, JString, required = false,
                                 default = nil)
  if valid_605174 != nil:
    section.add "X-Amz-Credential", valid_605174
  var valid_605175 = header.getOrDefault("X-Amz-Security-Token")
  valid_605175 = validateParameter(valid_605175, JString, required = false,
                                 default = nil)
  if valid_605175 != nil:
    section.add "X-Amz-Security-Token", valid_605175
  var valid_605176 = header.getOrDefault("X-Amz-Algorithm")
  valid_605176 = validateParameter(valid_605176, JString, required = false,
                                 default = nil)
  if valid_605176 != nil:
    section.add "X-Amz-Algorithm", valid_605176
  var valid_605177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605177 = validateParameter(valid_605177, JString, required = false,
                                 default = nil)
  if valid_605177 != nil:
    section.add "X-Amz-SignedHeaders", valid_605177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605178: Call_DeleteFileSystemPolicy_605167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the <code>FileSystemPolicy</code> for the specified file system. The default <code>FileSystemPolicy</code> goes into effect once the existing policy is deleted. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystemPolicy</code> action.</p>
  ## 
  let valid = call_605178.validator(path, query, header, formData, body)
  let scheme = call_605178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605178.url(scheme.get, call_605178.host, call_605178.base,
                         call_605178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605178, url, valid)

proc call*(call_605179: Call_DeleteFileSystemPolicy_605167; FileSystemId: string): Recallable =
  ## deleteFileSystemPolicy
  ## <p>Deletes the <code>FileSystemPolicy</code> for the specified file system. The default <code>FileSystemPolicy</code> goes into effect once the existing policy is deleted. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystemPolicy</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : Specifies the EFS file system for which to delete the <code>FileSystemPolicy</code>.
  var path_605180 = newJObject()
  add(path_605180, "FileSystemId", newJString(FileSystemId))
  result = call_605179.call(path_605180, nil, nil, nil, nil)

var deleteFileSystemPolicy* = Call_DeleteFileSystemPolicy_605167(
    name: "deleteFileSystemPolicy", meth: HttpMethod.HttpDelete,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/policy",
    validator: validate_DeleteFileSystemPolicy_605168, base: "/",
    url: url_DeleteFileSystemPolicy_605169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMountTarget_605181 = ref object of OpenApiRestCall_604389
proc url_DeleteMountTarget_605183(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMountTarget_605182(path: JsonNode; query: JsonNode;
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
  var valid_605184 = path.getOrDefault("MountTargetId")
  valid_605184 = validateParameter(valid_605184, JString, required = true,
                                 default = nil)
  if valid_605184 != nil:
    section.add "MountTargetId", valid_605184
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
  var valid_605185 = header.getOrDefault("X-Amz-Signature")
  valid_605185 = validateParameter(valid_605185, JString, required = false,
                                 default = nil)
  if valid_605185 != nil:
    section.add "X-Amz-Signature", valid_605185
  var valid_605186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605186 = validateParameter(valid_605186, JString, required = false,
                                 default = nil)
  if valid_605186 != nil:
    section.add "X-Amz-Content-Sha256", valid_605186
  var valid_605187 = header.getOrDefault("X-Amz-Date")
  valid_605187 = validateParameter(valid_605187, JString, required = false,
                                 default = nil)
  if valid_605187 != nil:
    section.add "X-Amz-Date", valid_605187
  var valid_605188 = header.getOrDefault("X-Amz-Credential")
  valid_605188 = validateParameter(valid_605188, JString, required = false,
                                 default = nil)
  if valid_605188 != nil:
    section.add "X-Amz-Credential", valid_605188
  var valid_605189 = header.getOrDefault("X-Amz-Security-Token")
  valid_605189 = validateParameter(valid_605189, JString, required = false,
                                 default = nil)
  if valid_605189 != nil:
    section.add "X-Amz-Security-Token", valid_605189
  var valid_605190 = header.getOrDefault("X-Amz-Algorithm")
  valid_605190 = validateParameter(valid_605190, JString, required = false,
                                 default = nil)
  if valid_605190 != nil:
    section.add "X-Amz-Algorithm", valid_605190
  var valid_605191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605191 = validateParameter(valid_605191, JString, required = false,
                                 default = nil)
  if valid_605191 != nil:
    section.add "X-Amz-SignedHeaders", valid_605191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605192: Call_DeleteMountTarget_605181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_605192.validator(path, query, header, formData, body)
  let scheme = call_605192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605192.url(scheme.get, call_605192.host, call_605192.base,
                         call_605192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605192, url, valid)

proc call*(call_605193: Call_DeleteMountTarget_605181; MountTargetId: string): Recallable =
  ## deleteMountTarget
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target to delete (String).
  var path_605194 = newJObject()
  add(path_605194, "MountTargetId", newJString(MountTargetId))
  result = call_605193.call(path_605194, nil, nil, nil, nil)

var deleteMountTarget* = Call_DeleteMountTarget_605181(name: "deleteMountTarget",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}",
    validator: validate_DeleteMountTarget_605182, base: "/",
    url: url_DeleteMountTarget_605183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_605195 = ref object of OpenApiRestCall_604389
proc url_DeleteTags_605197(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_605196(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605198 = path.getOrDefault("FileSystemId")
  valid_605198 = validateParameter(valid_605198, JString, required = true,
                                 default = nil)
  if valid_605198 != nil:
    section.add "FileSystemId", valid_605198
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
  var valid_605199 = header.getOrDefault("X-Amz-Signature")
  valid_605199 = validateParameter(valid_605199, JString, required = false,
                                 default = nil)
  if valid_605199 != nil:
    section.add "X-Amz-Signature", valid_605199
  var valid_605200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605200 = validateParameter(valid_605200, JString, required = false,
                                 default = nil)
  if valid_605200 != nil:
    section.add "X-Amz-Content-Sha256", valid_605200
  var valid_605201 = header.getOrDefault("X-Amz-Date")
  valid_605201 = validateParameter(valid_605201, JString, required = false,
                                 default = nil)
  if valid_605201 != nil:
    section.add "X-Amz-Date", valid_605201
  var valid_605202 = header.getOrDefault("X-Amz-Credential")
  valid_605202 = validateParameter(valid_605202, JString, required = false,
                                 default = nil)
  if valid_605202 != nil:
    section.add "X-Amz-Credential", valid_605202
  var valid_605203 = header.getOrDefault("X-Amz-Security-Token")
  valid_605203 = validateParameter(valid_605203, JString, required = false,
                                 default = nil)
  if valid_605203 != nil:
    section.add "X-Amz-Security-Token", valid_605203
  var valid_605204 = header.getOrDefault("X-Amz-Algorithm")
  valid_605204 = validateParameter(valid_605204, JString, required = false,
                                 default = nil)
  if valid_605204 != nil:
    section.add "X-Amz-Algorithm", valid_605204
  var valid_605205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605205 = validateParameter(valid_605205, JString, required = false,
                                 default = nil)
  if valid_605205 != nil:
    section.add "X-Amz-SignedHeaders", valid_605205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605207: Call_DeleteTags_605195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ## 
  let valid = call_605207.validator(path, query, header, formData, body)
  let scheme = call_605207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605207.url(scheme.get, call_605207.host, call_605207.base,
                         call_605207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605207, url, valid)

proc call*(call_605208: Call_DeleteTags_605195; FileSystemId: string; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to delete (String).
  ##   body: JObject (required)
  var path_605209 = newJObject()
  var body_605210 = newJObject()
  add(path_605209, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_605210 = body
  result = call_605208.call(path_605209, nil, nil, nil, body_605210)

var deleteTags* = Call_DeleteTags_605195(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/delete-tags/{FileSystemId}",
                                      validator: validate_DeleteTags_605196,
                                      base: "/", url: url_DeleteTags_605197,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleConfiguration_605225 = ref object of OpenApiRestCall_604389
proc url_PutLifecycleConfiguration_605227(protocol: Scheme; host: string;
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

proc validate_PutLifecycleConfiguration_605226(path: JsonNode; query: JsonNode;
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
  var valid_605228 = path.getOrDefault("FileSystemId")
  valid_605228 = validateParameter(valid_605228, JString, required = true,
                                 default = nil)
  if valid_605228 != nil:
    section.add "FileSystemId", valid_605228
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
  var valid_605229 = header.getOrDefault("X-Amz-Signature")
  valid_605229 = validateParameter(valid_605229, JString, required = false,
                                 default = nil)
  if valid_605229 != nil:
    section.add "X-Amz-Signature", valid_605229
  var valid_605230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605230 = validateParameter(valid_605230, JString, required = false,
                                 default = nil)
  if valid_605230 != nil:
    section.add "X-Amz-Content-Sha256", valid_605230
  var valid_605231 = header.getOrDefault("X-Amz-Date")
  valid_605231 = validateParameter(valid_605231, JString, required = false,
                                 default = nil)
  if valid_605231 != nil:
    section.add "X-Amz-Date", valid_605231
  var valid_605232 = header.getOrDefault("X-Amz-Credential")
  valid_605232 = validateParameter(valid_605232, JString, required = false,
                                 default = nil)
  if valid_605232 != nil:
    section.add "X-Amz-Credential", valid_605232
  var valid_605233 = header.getOrDefault("X-Amz-Security-Token")
  valid_605233 = validateParameter(valid_605233, JString, required = false,
                                 default = nil)
  if valid_605233 != nil:
    section.add "X-Amz-Security-Token", valid_605233
  var valid_605234 = header.getOrDefault("X-Amz-Algorithm")
  valid_605234 = validateParameter(valid_605234, JString, required = false,
                                 default = nil)
  if valid_605234 != nil:
    section.add "X-Amz-Algorithm", valid_605234
  var valid_605235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605235 = validateParameter(valid_605235, JString, required = false,
                                 default = nil)
  if valid_605235 != nil:
    section.add "X-Amz-SignedHeaders", valid_605235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605237: Call_PutLifecycleConfiguration_605225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ## 
  let valid = call_605237.validator(path, query, header, formData, body)
  let scheme = call_605237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605237.url(scheme.get, call_605237.host, call_605237.base,
                         call_605237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605237, url, valid)

proc call*(call_605238: Call_PutLifecycleConfiguration_605225;
          FileSystemId: string; body: JsonNode): Recallable =
  ## putLifecycleConfiguration
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system for which you are creating the <code>LifecycleConfiguration</code> object (String).
  ##   body: JObject (required)
  var path_605239 = newJObject()
  var body_605240 = newJObject()
  add(path_605239, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_605240 = body
  result = call_605238.call(path_605239, nil, nil, nil, body_605240)

var putLifecycleConfiguration* = Call_PutLifecycleConfiguration_605225(
    name: "putLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_PutLifecycleConfiguration_605226, base: "/",
    url: url_PutLifecycleConfiguration_605227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLifecycleConfiguration_605211 = ref object of OpenApiRestCall_604389
proc url_DescribeLifecycleConfiguration_605213(protocol: Scheme; host: string;
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

proc validate_DescribeLifecycleConfiguration_605212(path: JsonNode;
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
  var valid_605214 = path.getOrDefault("FileSystemId")
  valid_605214 = validateParameter(valid_605214, JString, required = true,
                                 default = nil)
  if valid_605214 != nil:
    section.add "FileSystemId", valid_605214
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
  var valid_605215 = header.getOrDefault("X-Amz-Signature")
  valid_605215 = validateParameter(valid_605215, JString, required = false,
                                 default = nil)
  if valid_605215 != nil:
    section.add "X-Amz-Signature", valid_605215
  var valid_605216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605216 = validateParameter(valid_605216, JString, required = false,
                                 default = nil)
  if valid_605216 != nil:
    section.add "X-Amz-Content-Sha256", valid_605216
  var valid_605217 = header.getOrDefault("X-Amz-Date")
  valid_605217 = validateParameter(valid_605217, JString, required = false,
                                 default = nil)
  if valid_605217 != nil:
    section.add "X-Amz-Date", valid_605217
  var valid_605218 = header.getOrDefault("X-Amz-Credential")
  valid_605218 = validateParameter(valid_605218, JString, required = false,
                                 default = nil)
  if valid_605218 != nil:
    section.add "X-Amz-Credential", valid_605218
  var valid_605219 = header.getOrDefault("X-Amz-Security-Token")
  valid_605219 = validateParameter(valid_605219, JString, required = false,
                                 default = nil)
  if valid_605219 != nil:
    section.add "X-Amz-Security-Token", valid_605219
  var valid_605220 = header.getOrDefault("X-Amz-Algorithm")
  valid_605220 = validateParameter(valid_605220, JString, required = false,
                                 default = nil)
  if valid_605220 != nil:
    section.add "X-Amz-Algorithm", valid_605220
  var valid_605221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605221 = validateParameter(valid_605221, JString, required = false,
                                 default = nil)
  if valid_605221 != nil:
    section.add "X-Amz-SignedHeaders", valid_605221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605222: Call_DescribeLifecycleConfiguration_605211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ## 
  let valid = call_605222.validator(path, query, header, formData, body)
  let scheme = call_605222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605222.url(scheme.get, call_605222.host, call_605222.base,
                         call_605222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605222, url, valid)

proc call*(call_605223: Call_DescribeLifecycleConfiguration_605211;
          FileSystemId: string): Recallable =
  ## describeLifecycleConfiguration
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose <code>LifecycleConfiguration</code> object you want to retrieve (String).
  var path_605224 = newJObject()
  add(path_605224, "FileSystemId", newJString(FileSystemId))
  result = call_605223.call(path_605224, nil, nil, nil, nil)

var describeLifecycleConfiguration* = Call_DescribeLifecycleConfiguration_605211(
    name: "describeLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_DescribeLifecycleConfiguration_605212, base: "/",
    url: url_DescribeLifecycleConfiguration_605213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyMountTargetSecurityGroups_605255 = ref object of OpenApiRestCall_604389
proc url_ModifyMountTargetSecurityGroups_605257(protocol: Scheme; host: string;
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

proc validate_ModifyMountTargetSecurityGroups_605256(path: JsonNode;
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
  var valid_605258 = path.getOrDefault("MountTargetId")
  valid_605258 = validateParameter(valid_605258, JString, required = true,
                                 default = nil)
  if valid_605258 != nil:
    section.add "MountTargetId", valid_605258
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
  var valid_605259 = header.getOrDefault("X-Amz-Signature")
  valid_605259 = validateParameter(valid_605259, JString, required = false,
                                 default = nil)
  if valid_605259 != nil:
    section.add "X-Amz-Signature", valid_605259
  var valid_605260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605260 = validateParameter(valid_605260, JString, required = false,
                                 default = nil)
  if valid_605260 != nil:
    section.add "X-Amz-Content-Sha256", valid_605260
  var valid_605261 = header.getOrDefault("X-Amz-Date")
  valid_605261 = validateParameter(valid_605261, JString, required = false,
                                 default = nil)
  if valid_605261 != nil:
    section.add "X-Amz-Date", valid_605261
  var valid_605262 = header.getOrDefault("X-Amz-Credential")
  valid_605262 = validateParameter(valid_605262, JString, required = false,
                                 default = nil)
  if valid_605262 != nil:
    section.add "X-Amz-Credential", valid_605262
  var valid_605263 = header.getOrDefault("X-Amz-Security-Token")
  valid_605263 = validateParameter(valid_605263, JString, required = false,
                                 default = nil)
  if valid_605263 != nil:
    section.add "X-Amz-Security-Token", valid_605263
  var valid_605264 = header.getOrDefault("X-Amz-Algorithm")
  valid_605264 = validateParameter(valid_605264, JString, required = false,
                                 default = nil)
  if valid_605264 != nil:
    section.add "X-Amz-Algorithm", valid_605264
  var valid_605265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605265 = validateParameter(valid_605265, JString, required = false,
                                 default = nil)
  if valid_605265 != nil:
    section.add "X-Amz-SignedHeaders", valid_605265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605267: Call_ModifyMountTargetSecurityGroups_605255;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_605267.validator(path, query, header, formData, body)
  let scheme = call_605267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605267.url(scheme.get, call_605267.host, call_605267.base,
                         call_605267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605267, url, valid)

proc call*(call_605268: Call_ModifyMountTargetSecurityGroups_605255;
          MountTargetId: string; body: JsonNode): Recallable =
  ## modifyMountTargetSecurityGroups
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to modify.
  ##   body: JObject (required)
  var path_605269 = newJObject()
  var body_605270 = newJObject()
  add(path_605269, "MountTargetId", newJString(MountTargetId))
  if body != nil:
    body_605270 = body
  result = call_605268.call(path_605269, nil, nil, nil, body_605270)

var modifyMountTargetSecurityGroups* = Call_ModifyMountTargetSecurityGroups_605255(
    name: "modifyMountTargetSecurityGroups", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_ModifyMountTargetSecurityGroups_605256, base: "/",
    url: url_ModifyMountTargetSecurityGroups_605257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargetSecurityGroups_605241 = ref object of OpenApiRestCall_604389
proc url_DescribeMountTargetSecurityGroups_605243(protocol: Scheme; host: string;
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

proc validate_DescribeMountTargetSecurityGroups_605242(path: JsonNode;
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
  var valid_605244 = path.getOrDefault("MountTargetId")
  valid_605244 = validateParameter(valid_605244, JString, required = true,
                                 default = nil)
  if valid_605244 != nil:
    section.add "MountTargetId", valid_605244
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
  var valid_605245 = header.getOrDefault("X-Amz-Signature")
  valid_605245 = validateParameter(valid_605245, JString, required = false,
                                 default = nil)
  if valid_605245 != nil:
    section.add "X-Amz-Signature", valid_605245
  var valid_605246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605246 = validateParameter(valid_605246, JString, required = false,
                                 default = nil)
  if valid_605246 != nil:
    section.add "X-Amz-Content-Sha256", valid_605246
  var valid_605247 = header.getOrDefault("X-Amz-Date")
  valid_605247 = validateParameter(valid_605247, JString, required = false,
                                 default = nil)
  if valid_605247 != nil:
    section.add "X-Amz-Date", valid_605247
  var valid_605248 = header.getOrDefault("X-Amz-Credential")
  valid_605248 = validateParameter(valid_605248, JString, required = false,
                                 default = nil)
  if valid_605248 != nil:
    section.add "X-Amz-Credential", valid_605248
  var valid_605249 = header.getOrDefault("X-Amz-Security-Token")
  valid_605249 = validateParameter(valid_605249, JString, required = false,
                                 default = nil)
  if valid_605249 != nil:
    section.add "X-Amz-Security-Token", valid_605249
  var valid_605250 = header.getOrDefault("X-Amz-Algorithm")
  valid_605250 = validateParameter(valid_605250, JString, required = false,
                                 default = nil)
  if valid_605250 != nil:
    section.add "X-Amz-Algorithm", valid_605250
  var valid_605251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605251 = validateParameter(valid_605251, JString, required = false,
                                 default = nil)
  if valid_605251 != nil:
    section.add "X-Amz-SignedHeaders", valid_605251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605252: Call_DescribeMountTargetSecurityGroups_605241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_605252.validator(path, query, header, formData, body)
  let scheme = call_605252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605252.url(scheme.get, call_605252.host, call_605252.base,
                         call_605252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605252, url, valid)

proc call*(call_605253: Call_DescribeMountTargetSecurityGroups_605241;
          MountTargetId: string): Recallable =
  ## describeMountTargetSecurityGroups
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to retrieve.
  var path_605254 = newJObject()
  add(path_605254, "MountTargetId", newJString(MountTargetId))
  result = call_605253.call(path_605254, nil, nil, nil, nil)

var describeMountTargetSecurityGroups* = Call_DescribeMountTargetSecurityGroups_605241(
    name: "describeMountTargetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_DescribeMountTargetSecurityGroups_605242, base: "/",
    url: url_DescribeMountTargetSecurityGroups_605243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_605271 = ref object of OpenApiRestCall_604389
proc url_DescribeTags_605273(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_605272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605274 = path.getOrDefault("FileSystemId")
  valid_605274 = validateParameter(valid_605274, JString, required = true,
                                 default = nil)
  if valid_605274 != nil:
    section.add "FileSystemId", valid_605274
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: JInt
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 100, and other values are ignored. The response is paginated at 100 per page if you have more than 100 tags.
  section = newJObject()
  var valid_605275 = query.getOrDefault("Marker")
  valid_605275 = validateParameter(valid_605275, JString, required = false,
                                 default = nil)
  if valid_605275 != nil:
    section.add "Marker", valid_605275
  var valid_605276 = query.getOrDefault("MaxItems")
  valid_605276 = validateParameter(valid_605276, JInt, required = false, default = nil)
  if valid_605276 != nil:
    section.add "MaxItems", valid_605276
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
  var valid_605277 = header.getOrDefault("X-Amz-Signature")
  valid_605277 = validateParameter(valid_605277, JString, required = false,
                                 default = nil)
  if valid_605277 != nil:
    section.add "X-Amz-Signature", valid_605277
  var valid_605278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605278 = validateParameter(valid_605278, JString, required = false,
                                 default = nil)
  if valid_605278 != nil:
    section.add "X-Amz-Content-Sha256", valid_605278
  var valid_605279 = header.getOrDefault("X-Amz-Date")
  valid_605279 = validateParameter(valid_605279, JString, required = false,
                                 default = nil)
  if valid_605279 != nil:
    section.add "X-Amz-Date", valid_605279
  var valid_605280 = header.getOrDefault("X-Amz-Credential")
  valid_605280 = validateParameter(valid_605280, JString, required = false,
                                 default = nil)
  if valid_605280 != nil:
    section.add "X-Amz-Credential", valid_605280
  var valid_605281 = header.getOrDefault("X-Amz-Security-Token")
  valid_605281 = validateParameter(valid_605281, JString, required = false,
                                 default = nil)
  if valid_605281 != nil:
    section.add "X-Amz-Security-Token", valid_605281
  var valid_605282 = header.getOrDefault("X-Amz-Algorithm")
  valid_605282 = validateParameter(valid_605282, JString, required = false,
                                 default = nil)
  if valid_605282 != nil:
    section.add "X-Amz-Algorithm", valid_605282
  var valid_605283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605283 = validateParameter(valid_605283, JString, required = false,
                                 default = nil)
  if valid_605283 != nil:
    section.add "X-Amz-SignedHeaders", valid_605283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605284: Call_DescribeTags_605271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ## 
  let valid = call_605284.validator(path, query, header, formData, body)
  let scheme = call_605284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605284.url(scheme.get, call_605284.host, call_605284.base,
                         call_605284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605284, url, valid)

proc call*(call_605285: Call_DescribeTags_605271; FileSystemId: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## describeTags
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ##   Marker: string
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: int
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 100, and other values are ignored. The response is paginated at 100 per page if you have more than 100 tags.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tag set you want to retrieve.
  var path_605286 = newJObject()
  var query_605287 = newJObject()
  add(query_605287, "Marker", newJString(Marker))
  add(query_605287, "MaxItems", newJInt(MaxItems))
  add(path_605286, "FileSystemId", newJString(FileSystemId))
  result = call_605285.call(path_605286, query_605287, nil, nil, nil)

var describeTags* = Call_DescribeTags_605271(name: "describeTags",
    meth: HttpMethod.HttpGet, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/tags/{FileSystemId}/", validator: validate_DescribeTags_605272,
    base: "/", url: url_DescribeTags_605273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_605305 = ref object of OpenApiRestCall_604389
proc url_TagResource_605307(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/resource-tags/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_605306(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a tag for an EFS resource. You can create tags for EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:TagResource</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID specifying the EFS resource that you want to create a tag for. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_605308 = path.getOrDefault("ResourceId")
  valid_605308 = validateParameter(valid_605308, JString, required = true,
                                 default = nil)
  if valid_605308 != nil:
    section.add "ResourceId", valid_605308
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
  var valid_605309 = header.getOrDefault("X-Amz-Signature")
  valid_605309 = validateParameter(valid_605309, JString, required = false,
                                 default = nil)
  if valid_605309 != nil:
    section.add "X-Amz-Signature", valid_605309
  var valid_605310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605310 = validateParameter(valid_605310, JString, required = false,
                                 default = nil)
  if valid_605310 != nil:
    section.add "X-Amz-Content-Sha256", valid_605310
  var valid_605311 = header.getOrDefault("X-Amz-Date")
  valid_605311 = validateParameter(valid_605311, JString, required = false,
                                 default = nil)
  if valid_605311 != nil:
    section.add "X-Amz-Date", valid_605311
  var valid_605312 = header.getOrDefault("X-Amz-Credential")
  valid_605312 = validateParameter(valid_605312, JString, required = false,
                                 default = nil)
  if valid_605312 != nil:
    section.add "X-Amz-Credential", valid_605312
  var valid_605313 = header.getOrDefault("X-Amz-Security-Token")
  valid_605313 = validateParameter(valid_605313, JString, required = false,
                                 default = nil)
  if valid_605313 != nil:
    section.add "X-Amz-Security-Token", valid_605313
  var valid_605314 = header.getOrDefault("X-Amz-Algorithm")
  valid_605314 = validateParameter(valid_605314, JString, required = false,
                                 default = nil)
  if valid_605314 != nil:
    section.add "X-Amz-Algorithm", valid_605314
  var valid_605315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605315 = validateParameter(valid_605315, JString, required = false,
                                 default = nil)
  if valid_605315 != nil:
    section.add "X-Amz-SignedHeaders", valid_605315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605317: Call_TagResource_605305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a tag for an EFS resource. You can create tags for EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:TagResource</code> action.</p>
  ## 
  let valid = call_605317.validator(path, query, header, formData, body)
  let scheme = call_605317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605317.url(scheme.get, call_605317.host, call_605317.base,
                         call_605317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605317, url, valid)

proc call*(call_605318: Call_TagResource_605305; ResourceId: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Creates a tag for an EFS resource. You can create tags for EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:TagResource</code> action.</p>
  ##   ResourceId: string (required)
  ##             : The ID specifying the EFS resource that you want to create a tag for. 
  ##   body: JObject (required)
  var path_605319 = newJObject()
  var body_605320 = newJObject()
  add(path_605319, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_605320 = body
  result = call_605318.call(path_605319, nil, nil, nil, body_605320)

var tagResource* = Call_TagResource_605305(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/resource-tags/{ResourceId}",
                                        validator: validate_TagResource_605306,
                                        base: "/", url: url_TagResource_605307,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_605288 = ref object of OpenApiRestCall_604389
proc url_ListTagsForResource_605290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/resource-tags/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_605289(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists all tags for a top-level EFS resource. You must provide the ID of the resource that you want to retrieve the tags for.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : Specifies the EFS resource you want to retrieve tags for. You can retrieve tags for EFS file systems and access points using this API endpoint.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_605291 = path.getOrDefault("ResourceId")
  valid_605291 = validateParameter(valid_605291, JString, required = true,
                                 default = nil)
  if valid_605291 != nil:
    section.add "ResourceId", valid_605291
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : (Optional) Specifies the maximum number of tag objects to return in the response. The default value is 100.
  ##   NextToken: JString
  ##            : You can use <code>NextToken</code> in a subsequent request to fetch the next page of access point descriptions if the response payload was paginated.
  section = newJObject()
  var valid_605292 = query.getOrDefault("MaxResults")
  valid_605292 = validateParameter(valid_605292, JInt, required = false, default = nil)
  if valid_605292 != nil:
    section.add "MaxResults", valid_605292
  var valid_605293 = query.getOrDefault("NextToken")
  valid_605293 = validateParameter(valid_605293, JString, required = false,
                                 default = nil)
  if valid_605293 != nil:
    section.add "NextToken", valid_605293
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
  var valid_605294 = header.getOrDefault("X-Amz-Signature")
  valid_605294 = validateParameter(valid_605294, JString, required = false,
                                 default = nil)
  if valid_605294 != nil:
    section.add "X-Amz-Signature", valid_605294
  var valid_605295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605295 = validateParameter(valid_605295, JString, required = false,
                                 default = nil)
  if valid_605295 != nil:
    section.add "X-Amz-Content-Sha256", valid_605295
  var valid_605296 = header.getOrDefault("X-Amz-Date")
  valid_605296 = validateParameter(valid_605296, JString, required = false,
                                 default = nil)
  if valid_605296 != nil:
    section.add "X-Amz-Date", valid_605296
  var valid_605297 = header.getOrDefault("X-Amz-Credential")
  valid_605297 = validateParameter(valid_605297, JString, required = false,
                                 default = nil)
  if valid_605297 != nil:
    section.add "X-Amz-Credential", valid_605297
  var valid_605298 = header.getOrDefault("X-Amz-Security-Token")
  valid_605298 = validateParameter(valid_605298, JString, required = false,
                                 default = nil)
  if valid_605298 != nil:
    section.add "X-Amz-Security-Token", valid_605298
  var valid_605299 = header.getOrDefault("X-Amz-Algorithm")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "X-Amz-Algorithm", valid_605299
  var valid_605300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605300 = validateParameter(valid_605300, JString, required = false,
                                 default = nil)
  if valid_605300 != nil:
    section.add "X-Amz-SignedHeaders", valid_605300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605301: Call_ListTagsForResource_605288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all tags for a top-level EFS resource. You must provide the ID of the resource that you want to retrieve the tags for.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ## 
  let valid = call_605301.validator(path, query, header, formData, body)
  let scheme = call_605301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605301.url(scheme.get, call_605301.host, call_605301.base,
                         call_605301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605301, url, valid)

proc call*(call_605302: Call_ListTagsForResource_605288; ResourceId: string;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists all tags for a top-level EFS resource. You must provide the ID of the resource that you want to retrieve the tags for.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ##   MaxResults: int
  ##             : (Optional) Specifies the maximum number of tag objects to return in the response. The default value is 100.
  ##   ResourceId: string (required)
  ##             : Specifies the EFS resource you want to retrieve tags for. You can retrieve tags for EFS file systems and access points using this API endpoint.
  ##   NextToken: string
  ##            : You can use <code>NextToken</code> in a subsequent request to fetch the next page of access point descriptions if the response payload was paginated.
  var path_605303 = newJObject()
  var query_605304 = newJObject()
  add(query_605304, "MaxResults", newJInt(MaxResults))
  add(path_605303, "ResourceId", newJString(ResourceId))
  add(query_605304, "NextToken", newJString(NextToken))
  result = call_605302.call(path_605303, query_605304, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_605288(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/resource-tags/{ResourceId}",
    validator: validate_ListTagsForResource_605289, base: "/",
    url: url_ListTagsForResource_605290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_605321 = ref object of OpenApiRestCall_604389
proc url_UntagResource_605323(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/resource-tags/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_605322(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes tags from an EFS resource. You can remove tags from EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:UntagResource</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : Specifies the EFS resource that you want to remove tags from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_605324 = path.getOrDefault("ResourceId")
  valid_605324 = validateParameter(valid_605324, JString, required = true,
                                 default = nil)
  if valid_605324 != nil:
    section.add "ResourceId", valid_605324
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
  var valid_605325 = header.getOrDefault("X-Amz-Signature")
  valid_605325 = validateParameter(valid_605325, JString, required = false,
                                 default = nil)
  if valid_605325 != nil:
    section.add "X-Amz-Signature", valid_605325
  var valid_605326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605326 = validateParameter(valid_605326, JString, required = false,
                                 default = nil)
  if valid_605326 != nil:
    section.add "X-Amz-Content-Sha256", valid_605326
  var valid_605327 = header.getOrDefault("X-Amz-Date")
  valid_605327 = validateParameter(valid_605327, JString, required = false,
                                 default = nil)
  if valid_605327 != nil:
    section.add "X-Amz-Date", valid_605327
  var valid_605328 = header.getOrDefault("X-Amz-Credential")
  valid_605328 = validateParameter(valid_605328, JString, required = false,
                                 default = nil)
  if valid_605328 != nil:
    section.add "X-Amz-Credential", valid_605328
  var valid_605329 = header.getOrDefault("X-Amz-Security-Token")
  valid_605329 = validateParameter(valid_605329, JString, required = false,
                                 default = nil)
  if valid_605329 != nil:
    section.add "X-Amz-Security-Token", valid_605329
  var valid_605330 = header.getOrDefault("X-Amz-Algorithm")
  valid_605330 = validateParameter(valid_605330, JString, required = false,
                                 default = nil)
  if valid_605330 != nil:
    section.add "X-Amz-Algorithm", valid_605330
  var valid_605331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605331 = validateParameter(valid_605331, JString, required = false,
                                 default = nil)
  if valid_605331 != nil:
    section.add "X-Amz-SignedHeaders", valid_605331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605333: Call_UntagResource_605321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes tags from an EFS resource. You can remove tags from EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:UntagResource</code> action.</p>
  ## 
  let valid = call_605333.validator(path, query, header, formData, body)
  let scheme = call_605333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605333.url(scheme.get, call_605333.host, call_605333.base,
                         call_605333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605333, url, valid)

proc call*(call_605334: Call_UntagResource_605321; ResourceId: string; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes tags from an EFS resource. You can remove tags from EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:UntagResource</code> action.</p>
  ##   ResourceId: string (required)
  ##             : Specifies the EFS resource that you want to remove tags from.
  ##   body: JObject (required)
  var path_605335 = newJObject()
  var body_605336 = newJObject()
  add(path_605335, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_605336 = body
  result = call_605334.call(path_605335, nil, nil, nil, body_605336)

var untagResource* = Call_UntagResource_605321(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/resource-tags/{ResourceId}",
    validator: validate_UntagResource_605322, base: "/", url: url_UntagResource_605323,
    schemes: {Scheme.Https, Scheme.Http})
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
