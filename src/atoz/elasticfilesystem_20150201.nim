
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "elasticfilesystem.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticfilesystem.ap-southeast-1.amazonaws.com", "us-west-2": "elasticfilesystem.us-west-2.amazonaws.com", "eu-west-2": "elasticfilesystem.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticfilesystem.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticfilesystem.eu-central-1.amazonaws.com", "us-east-2": "elasticfilesystem.us-east-2.amazonaws.com", "us-east-1": "elasticfilesystem.us-east-1.amazonaws.com", "cn-northwest-1": "elasticfilesystem.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticfilesystem.ap-south-1.amazonaws.com", "eu-north-1": "elasticfilesystem.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticfilesystem.ap-northeast-2.amazonaws.com", "us-west-1": "elasticfilesystem.us-west-1.amazonaws.com", "us-gov-east-1": "elasticfilesystem.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticfilesystem.eu-west-3.amazonaws.com", "cn-north-1": "elasticfilesystem.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticfilesystem.sa-east-1.amazonaws.com", "eu-west-1": "elasticfilesystem.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticfilesystem.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticfilesystem.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticfilesystem.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateAccessPoint_402656479 = ref object of OpenApiRestCall_402656044
proc url_CreateAccessPoint_402656481(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAccessPoint_402656480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in its own directory and below. To learn more, see <a href="https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html">Mounting a File System Using EFS Access Points</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:CreateAccessPoint</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656482 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Security-Token", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Signature")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Signature", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Algorithm", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Date")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Date", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Credential")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Credential", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656490: Call_CreateAccessPoint_402656479;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in its own directory and below. To learn more, see <a href="https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html">Mounting a File System Using EFS Access Points</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:CreateAccessPoint</code> action.</p>
                                                                                         ## 
  let valid = call_402656490.validator(path, query, header, formData, body, _)
  let scheme = call_402656490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656490.makeUrl(scheme.get, call_402656490.host, call_402656490.base,
                                   call_402656490.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656490, uri, valid, _)

proc call*(call_402656491: Call_CreateAccessPoint_402656479; body: JsonNode): Recallable =
  ## createAccessPoint
  ## <p>Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in its own directory and below. To learn more, see <a href="https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html">Mounting a File System Using EFS Access Points</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:CreateAccessPoint</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656492 = newJObject()
  if body != nil:
    body_402656492 = body
  result = call_402656491.call(nil, nil, nil, nil, body_402656492)

var createAccessPoint* = Call_CreateAccessPoint_402656479(
    name: "createAccessPoint", meth: HttpMethod.HttpPost,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/access-points",
    validator: validate_CreateAccessPoint_402656480, base: "/",
    makeUrl: url_CreateAccessPoint_402656481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccessPoints_402656294 = ref object of OpenApiRestCall_402656044
proc url_DescribeAccessPoints_402656296(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccessPoints_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the description of a specific Amazon EFS access point if the <code>AccessPointId</code> is provided. If you provide an EFS <code>FileSystemId</code>, it returns descriptions of all access points for that file system. You can provide either an <code>AccessPointId</code> or a <code>FileSystemId</code> in the request, but not both. </p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : (Optional) When retrieving all access points for a file system, you can optionally specify the <code>MaxItems</code> parameter to limit the number of objects returned in a response. The default value is 100. 
  ##   
                                                                                                                                                                                                                                                                   ## NextToken: JString
                                                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                                                   ## :  
                                                                                                                                                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                                   ## present 
                                                                                                                                                                                                                                                                   ## if 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                                   ## paginated. 
                                                                                                                                                                                                                                                                   ## You 
                                                                                                                                                                                                                                                                   ## can 
                                                                                                                                                                                                                                                                   ## use 
                                                                                                                                                                                                                                                                   ## <code>NextMarker</code> 
                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## subsequent 
                                                                                                                                                                                                                                                                   ## request 
                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                   ## fetch 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                                                                                   ## page 
                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                   ## access 
                                                                                                                                                                                                                                                                   ## point 
                                                                                                                                                                                                                                                                   ## descriptions.
  ##   
                                                                                                                                                                                                                                                                                   ## AccessPointId: JString
                                                                                                                                                                                                                                                                                   ##                
                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                   ## (Optional) 
                                                                                                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                                                                                                   ## an 
                                                                                                                                                                                                                                                                                   ## EFS 
                                                                                                                                                                                                                                                                                   ## access 
                                                                                                                                                                                                                                                                                   ## point 
                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                   ## describe 
                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                   ## response; 
                                                                                                                                                                                                                                                                                   ## mutually 
                                                                                                                                                                                                                                                                                   ## exclusive 
                                                                                                                                                                                                                                                                                   ## with 
                                                                                                                                                                                                                                                                                   ## <code>FileSystemId</code>.
  ##   
                                                                                                                                                                                                                                                                                                                ## FileSystemId: JString
                                                                                                                                                                                                                                                                                                                ##               
                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                ## (Optional) 
                                                                                                                                                                                                                                                                                                                ## If 
                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                ## provide 
                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                ## <code>FileSystemId</code>, 
                                                                                                                                                                                                                                                                                                                ## EFS 
                                                                                                                                                                                                                                                                                                                ## returns 
                                                                                                                                                                                                                                                                                                                ## all 
                                                                                                                                                                                                                                                                                                                ## access 
                                                                                                                                                                                                                                                                                                                ## points 
                                                                                                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                ## file 
                                                                                                                                                                                                                                                                                                                ## system; 
                                                                                                                                                                                                                                                                                                                ## mutually 
                                                                                                                                                                                                                                                                                                                ## exclusive 
                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                ## <code>AccessPointId</code>.
  section = newJObject()
  var valid_402656375 = query.getOrDefault("MaxResults")
  valid_402656375 = validateParameter(valid_402656375, JInt, required = false,
                                      default = nil)
  if valid_402656375 != nil:
    section.add "MaxResults", valid_402656375
  var valid_402656376 = query.getOrDefault("NextToken")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "NextToken", valid_402656376
  var valid_402656377 = query.getOrDefault("AccessPointId")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "AccessPointId", valid_402656377
  var valid_402656378 = query.getOrDefault("FileSystemId")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "FileSystemId", valid_402656378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656379 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Security-Token", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Signature")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Signature", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Algorithm", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Date")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Date", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Credential")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Credential", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656399: Call_DescribeAccessPoints_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the description of a specific Amazon EFS access point if the <code>AccessPointId</code> is provided. If you provide an EFS <code>FileSystemId</code>, it returns descriptions of all access points for that file system. You can provide either an <code>AccessPointId</code> or a <code>FileSystemId</code> in the request, but not both. </p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
                                                                                         ## 
  let valid = call_402656399.validator(path, query, header, formData, body, _)
  let scheme = call_402656399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656399.makeUrl(scheme.get, call_402656399.host, call_402656399.base,
                                   call_402656399.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656399, uri, valid, _)

proc call*(call_402656448: Call_DescribeAccessPoints_402656294;
           MaxResults: int = 0; NextToken: string = "";
           AccessPointId: string = ""; FileSystemId: string = ""): Recallable =
  ## describeAccessPoints
  ## <p>Returns the description of a specific Amazon EFS access point if the <code>AccessPointId</code> is provided. If you provide an EFS <code>FileSystemId</code>, it returns descriptions of all access points for that file system. You can provide either an <code>AccessPointId</code> or a <code>FileSystemId</code> in the request, but not both. </p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MaxResults: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## retrieving 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## points 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## system, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## optionally 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## <code>MaxItems</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## parameter 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## limit 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## objects 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 100. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## :  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## present 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## paginated. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <code>NextMarker</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## subsequent 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## fetch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## page 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## point 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## descriptions.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## AccessPointId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## EFS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## point 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## describe 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## response; 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## mutually 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## exclusive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <code>FileSystemId</code>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## FileSystemId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## provide 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>FileSystemId</code>, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## EFS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## returns 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## points 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## system; 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## mutually 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## exclusive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>AccessPointId</code>.
  var query_402656449 = newJObject()
  add(query_402656449, "MaxResults", newJInt(MaxResults))
  add(query_402656449, "NextToken", newJString(NextToken))
  add(query_402656449, "AccessPointId", newJString(AccessPointId))
  add(query_402656449, "FileSystemId", newJString(FileSystemId))
  result = call_402656448.call(nil, query_402656449, nil, nil, nil)

var describeAccessPoints* = Call_DescribeAccessPoints_402656294(
    name: "describeAccessPoints", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/access-points",
    validator: validate_DescribeAccessPoints_402656295, base: "/",
    makeUrl: url_DescribeAccessPoints_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFileSystem_402656510 = ref object of OpenApiRestCall_402656044
proc url_CreateFileSystem_402656512(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFileSystem_402656511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656513 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Security-Token", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Signature")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Signature", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Algorithm", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Date")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Date", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Credential")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Credential", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656521: Call_CreateFileSystem_402656510;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
                                                                                         ## 
  let valid = call_402656521.validator(path, query, header, formData, body, _)
  let scheme = call_402656521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656521.makeUrl(scheme.get, call_402656521.host, call_402656521.base,
                                   call_402656521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656521, uri, valid, _)

proc call*(call_402656522: Call_CreateFileSystem_402656510; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656523 = newJObject()
  if body != nil:
    body_402656523 = body
  result = call_402656522.call(nil, nil, nil, nil, body_402656523)

var createFileSystem* = Call_CreateFileSystem_402656510(
    name: "createFileSystem", meth: HttpMethod.HttpPost,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_CreateFileSystem_402656511, base: "/",
    makeUrl: url_CreateFileSystem_402656512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_402656493 = ref object of OpenApiRestCall_402656044
proc url_DescribeFileSystems_402656495(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFileSystems_402656494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : (Optional) Opaque pagination token returned from a previous <code>DescribeFileSystems</code> operation (String). If present, specifies to continue the list from where the returning call had left off. 
  ##   
                                                                                                                                                                                                                                                       ## CreationToken: JString
                                                                                                                                                                                                                                                       ##                
                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                       ## (Optional) 
                                                                                                                                                                                                                                                       ## Restricts 
                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                       ## list 
                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                       ## file 
                                                                                                                                                                                                                                                       ## system 
                                                                                                                                                                                                                                                       ## with 
                                                                                                                                                                                                                                                       ## this 
                                                                                                                                                                                                                                                       ## creation 
                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                       ## (String). 
                                                                                                                                                                                                                                                       ## You 
                                                                                                                                                                                                                                                       ## specify 
                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                       ## creation 
                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                       ## when 
                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                       ## create 
                                                                                                                                                                                                                                                       ## an 
                                                                                                                                                                                                                                                       ## Amazon 
                                                                                                                                                                                                                                                       ## EFS 
                                                                                                                                                                                                                                                       ## file 
                                                                                                                                                                                                                                                       ## system.
  ##   
                                                                                                                                                                                                                                                                 ## MaxItems: JInt
                                                                                                                                                                                                                                                                 ##           
                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                 ## (Optional) 
                                                                                                                                                                                                                                                                 ## Specifies 
                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                 ## maximum 
                                                                                                                                                                                                                                                                 ## number 
                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                 ## file 
                                                                                                                                                                                                                                                                 ## systems 
                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                 ## return 
                                                                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                                                                                 ## (integer). 
                                                                                                                                                                                                                                                                 ## This 
                                                                                                                                                                                                                                                                 ## number 
                                                                                                                                                                                                                                                                 ## is 
                                                                                                                                                                                                                                                                 ## automatically 
                                                                                                                                                                                                                                                                 ## set 
                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                 ## 100. 
                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                                                                                 ## is 
                                                                                                                                                                                                                                                                 ## paginated 
                                                                                                                                                                                                                                                                 ## at 
                                                                                                                                                                                                                                                                 ## 100 
                                                                                                                                                                                                                                                                 ## per 
                                                                                                                                                                                                                                                                 ## page 
                                                                                                                                                                                                                                                                 ## if 
                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                 ## have 
                                                                                                                                                                                                                                                                 ## more 
                                                                                                                                                                                                                                                                 ## than 
                                                                                                                                                                                                                                                                 ## 100 
                                                                                                                                                                                                                                                                 ## file 
                                                                                                                                                                                                                                                                 ## systems. 
  ##   
                                                                                                                                                                                                                                                                             ## FileSystemId: JString
                                                                                                                                                                                                                                                                             ##               
                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                             ## (Optional) 
                                                                                                                                                                                                                                                                             ## ID 
                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                             ## file 
                                                                                                                                                                                                                                                                             ## system 
                                                                                                                                                                                                                                                                             ## whose 
                                                                                                                                                                                                                                                                             ## description 
                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                             ## want 
                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                             ## retrieve 
                                                                                                                                                                                                                                                                             ## (String).
  section = newJObject()
  var valid_402656496 = query.getOrDefault("Marker")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "Marker", valid_402656496
  var valid_402656497 = query.getOrDefault("CreationToken")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "CreationToken", valid_402656497
  var valid_402656498 = query.getOrDefault("MaxItems")
  valid_402656498 = validateParameter(valid_402656498, JInt, required = false,
                                      default = nil)
  if valid_402656498 != nil:
    section.add "MaxItems", valid_402656498
  var valid_402656499 = query.getOrDefault("FileSystemId")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "FileSystemId", valid_402656499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656500 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Security-Token", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Signature")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Signature", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Algorithm", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Date")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Date", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Credential")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Credential", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656507: Call_DescribeFileSystems_402656493;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_DescribeFileSystems_402656493;
           Marker: string = ""; CreationToken: string = ""; MaxItems: int = 0;
           FileSystemId: string = ""): Recallable =
  ## describeFileSystems
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Opaque 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## <code>DescribeFileSystems</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## operation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## (String). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## present, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## continue 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## returning 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## had 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## left 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## off. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## CreationToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Restricts 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## creation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## (String). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## creation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## EFS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## system.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## MaxItems: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## systems 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (integer). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## This 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## automatically 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## 100. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## at 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## 100 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## per 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## page 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## have 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## more 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## than 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## 100 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## systems. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## FileSystemId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## description 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## (String).
  var query_402656509 = newJObject()
  add(query_402656509, "Marker", newJString(Marker))
  add(query_402656509, "CreationToken", newJString(CreationToken))
  add(query_402656509, "MaxItems", newJInt(MaxItems))
  add(query_402656509, "FileSystemId", newJString(FileSystemId))
  result = call_402656508.call(nil, query_402656509, nil, nil, nil)

var describeFileSystems* = Call_DescribeFileSystems_402656493(
    name: "describeFileSystems", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_DescribeFileSystems_402656494, base: "/",
    makeUrl: url_DescribeFileSystems_402656495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMountTarget_402656542 = ref object of OpenApiRestCall_402656044
proc url_CreateMountTarget_402656544(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMountTarget_402656543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656545 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Security-Token", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Signature")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Signature", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Algorithm", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Date")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Date", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Credential")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Credential", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656553: Call_CreateMountTarget_402656542;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656553.validator(path, query, header, formData, body, _)
  let scheme = call_402656553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656553.makeUrl(scheme.get, call_402656553.host, call_402656553.base,
                                   call_402656553.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656553, uri, valid, _)

proc call*(call_402656554: Call_CreateMountTarget_402656542; body: JsonNode): Recallable =
  ## createMountTarget
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656555 = newJObject()
  if body != nil:
    body_402656555 = body
  result = call_402656554.call(nil, nil, nil, nil, body_402656555)

var createMountTarget* = Call_CreateMountTarget_402656542(
    name: "createMountTarget", meth: HttpMethod.HttpPost,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_CreateMountTarget_402656543, base: "/",
    makeUrl: url_CreateMountTarget_402656544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargets_402656524 = ref object of OpenApiRestCall_402656044
proc url_DescribeMountTargets_402656526(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMountTargets_402656525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MountTargetId: JString
                                  ##                : (Optional) ID of the mount target that you want to have described (String). It must be included in your request if <code>FileSystemId</code> is not included. Accepts either a mount target ID or ARN as input.
  ##   
                                                                                                                                                                                                                                                                     ## Marker: JString
                                                                                                                                                                                                                                                                     ##         
                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                     ## (Optional) 
                                                                                                                                                                                                                                                                     ## Opaque 
                                                                                                                                                                                                                                                                     ## pagination 
                                                                                                                                                                                                                                                                     ## token 
                                                                                                                                                                                                                                                                     ## returned 
                                                                                                                                                                                                                                                                     ## from 
                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                     ## previous 
                                                                                                                                                                                                                                                                     ## <code>DescribeMountTargets</code> 
                                                                                                                                                                                                                                                                     ## operation 
                                                                                                                                                                                                                                                                     ## (String). 
                                                                                                                                                                                                                                                                     ## If 
                                                                                                                                                                                                                                                                     ## present, 
                                                                                                                                                                                                                                                                     ## it 
                                                                                                                                                                                                                                                                     ## specifies 
                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                     ## continue 
                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                     ## list 
                                                                                                                                                                                                                                                                     ## from 
                                                                                                                                                                                                                                                                     ## where 
                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                     ## previous 
                                                                                                                                                                                                                                                                     ## returning 
                                                                                                                                                                                                                                                                     ## call 
                                                                                                                                                                                                                                                                     ## left 
                                                                                                                                                                                                                                                                     ## off.
  ##   
                                                                                                                                                                                                                                                                            ## AccessPointId: JString
                                                                                                                                                                                                                                                                            ##                
                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                            ## (Optional) 
                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                            ## access 
                                                                                                                                                                                                                                                                            ## point 
                                                                                                                                                                                                                                                                            ## whose 
                                                                                                                                                                                                                                                                            ## mount 
                                                                                                                                                                                                                                                                            ## targets 
                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                            ## list. 
                                                                                                                                                                                                                                                                            ## It 
                                                                                                                                                                                                                                                                            ## must 
                                                                                                                                                                                                                                                                            ## be 
                                                                                                                                                                                                                                                                            ## included 
                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                            ## your 
                                                                                                                                                                                                                                                                            ## request 
                                                                                                                                                                                                                                                                            ## if 
                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                            ## <code>FileSystemId</code> 
                                                                                                                                                                                                                                                                            ## or 
                                                                                                                                                                                                                                                                            ## <code>MountTargetId</code> 
                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                            ## not 
                                                                                                                                                                                                                                                                            ## included 
                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                            ## your 
                                                                                                                                                                                                                                                                            ## request. 
                                                                                                                                                                                                                                                                            ## Accepts 
                                                                                                                                                                                                                                                                            ## either 
                                                                                                                                                                                                                                                                            ## an 
                                                                                                                                                                                                                                                                            ## access 
                                                                                                                                                                                                                                                                            ## point 
                                                                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                                                                            ## or 
                                                                                                                                                                                                                                                                            ## ARN 
                                                                                                                                                                                                                                                                            ## as 
                                                                                                                                                                                                                                                                            ## input.
  ##   
                                                                                                                                                                                                                                                                                     ## MaxItems: JInt
                                                                                                                                                                                                                                                                                     ##           
                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                     ## (Optional) 
                                                                                                                                                                                                                                                                                     ## Maximum 
                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                     ## mount 
                                                                                                                                                                                                                                                                                     ## targets 
                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                     ## return 
                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                     ## response. 
                                                                                                                                                                                                                                                                                     ## Currently, 
                                                                                                                                                                                                                                                                                     ## this 
                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                                                                     ## automatically 
                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                     ## 10, 
                                                                                                                                                                                                                                                                                     ## and 
                                                                                                                                                                                                                                                                                     ## other 
                                                                                                                                                                                                                                                                                     ## values 
                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                     ## ignored. 
                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                     ## response 
                                                                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                                                                     ## paginated 
                                                                                                                                                                                                                                                                                     ## at 
                                                                                                                                                                                                                                                                                     ## 100 
                                                                                                                                                                                                                                                                                     ## per 
                                                                                                                                                                                                                                                                                     ## page 
                                                                                                                                                                                                                                                                                     ## if 
                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                     ## have 
                                                                                                                                                                                                                                                                                     ## more 
                                                                                                                                                                                                                                                                                     ## than 
                                                                                                                                                                                                                                                                                     ## 100 
                                                                                                                                                                                                                                                                                     ## mount 
                                                                                                                                                                                                                                                                                     ## targets.
  ##   
                                                                                                                                                                                                                                                                                                ## FileSystemId: JString
                                                                                                                                                                                                                                                                                                ##               
                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                ## (Optional) 
                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                ## file 
                                                                                                                                                                                                                                                                                                ## system 
                                                                                                                                                                                                                                                                                                ## whose 
                                                                                                                                                                                                                                                                                                ## mount 
                                                                                                                                                                                                                                                                                                ## targets 
                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                ## list 
                                                                                                                                                                                                                                                                                                ## (String). 
                                                                                                                                                                                                                                                                                                ## It 
                                                                                                                                                                                                                                                                                                ## must 
                                                                                                                                                                                                                                                                                                ## be 
                                                                                                                                                                                                                                                                                                ## included 
                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                ## your 
                                                                                                                                                                                                                                                                                                ## request 
                                                                                                                                                                                                                                                                                                ## if 
                                                                                                                                                                                                                                                                                                ## an 
                                                                                                                                                                                                                                                                                                ## <code>AccessPointId</code> 
                                                                                                                                                                                                                                                                                                ## or 
                                                                                                                                                                                                                                                                                                ## <code>MountTargetId</code> 
                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                ## not 
                                                                                                                                                                                                                                                                                                ## included. 
                                                                                                                                                                                                                                                                                                ## Accepts 
                                                                                                                                                                                                                                                                                                ## either 
                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                ## file 
                                                                                                                                                                                                                                                                                                ## system 
                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                ## or 
                                                                                                                                                                                                                                                                                                ## ARN 
                                                                                                                                                                                                                                                                                                ## as 
                                                                                                                                                                                                                                                                                                ## input.
  section = newJObject()
  var valid_402656527 = query.getOrDefault("MountTargetId")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "MountTargetId", valid_402656527
  var valid_402656528 = query.getOrDefault("Marker")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "Marker", valid_402656528
  var valid_402656529 = query.getOrDefault("AccessPointId")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "AccessPointId", valid_402656529
  var valid_402656530 = query.getOrDefault("MaxItems")
  valid_402656530 = validateParameter(valid_402656530, JInt, required = false,
                                      default = nil)
  if valid_402656530 != nil:
    section.add "MaxItems", valid_402656530
  var valid_402656531 = query.getOrDefault("FileSystemId")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "FileSystemId", valid_402656531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656532 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Security-Token", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Signature")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Signature", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Algorithm", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Date")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Date", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Credential")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Credential", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656539: Call_DescribeMountTargets_402656524;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
                                                                                         ## 
  let valid = call_402656539.validator(path, query, header, formData, body, _)
  let scheme = call_402656539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656539.makeUrl(scheme.get, call_402656539.host, call_402656539.base,
                                   call_402656539.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656539, uri, valid, _)

proc call*(call_402656540: Call_DescribeMountTargets_402656524;
           MountTargetId: string = ""; Marker: string = "";
           AccessPointId: string = ""; MaxItems: int = 0;
           FileSystemId: string = ""): Recallable =
  ## describeMountTargets
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## MountTargetId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## target 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## have 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## described 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## (String). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## It 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## included 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <code>FileSystemId</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## included. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Accepts 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## either 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## target 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ARN 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## input.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Opaque 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## <code>DescribeMountTargets</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## operation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## (String). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## present, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## continue 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## returning 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## left 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## off.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## AccessPointId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## point 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## targets 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## list. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## It 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## included 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <code>FileSystemId</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <code>MountTargetId</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## included 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## request. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Accepts 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## either 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## point 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ARN 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## input.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## MaxItems: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## targets 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Currently, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## automatically 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## 10, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## other 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## ignored. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## at 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## 100 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## per 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## page 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## have 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## more 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## than 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## 100 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## targets.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## FileSystemId: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## targets 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (String). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## It 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## included 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <code>AccessPointId</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <code>MountTargetId</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## included. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Accepts 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## either 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ARN 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## input.
  var query_402656541 = newJObject()
  add(query_402656541, "MountTargetId", newJString(MountTargetId))
  add(query_402656541, "Marker", newJString(Marker))
  add(query_402656541, "AccessPointId", newJString(AccessPointId))
  add(query_402656541, "MaxItems", newJInt(MaxItems))
  add(query_402656541, "FileSystemId", newJString(FileSystemId))
  result = call_402656540.call(nil, query_402656541, nil, nil, nil)

var describeMountTargets* = Call_DescribeMountTargets_402656524(
    name: "describeMountTargets", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_DescribeMountTargets_402656525, base: "/",
    makeUrl: url_DescribeMountTargets_402656526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_402656556 = ref object of OpenApiRestCall_402656044
proc url_CreateTags_402656558(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_402656557(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656570 = path.getOrDefault("FileSystemId")
  valid_402656570 = validateParameter(valid_402656570, JString, required = true,
                                      default = nil)
  if valid_402656570 != nil:
    section.add "FileSystemId", valid_402656570
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656571 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Security-Token", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Signature")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Signature", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Algorithm", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Date")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Date", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Credential")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Credential", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656579: Call_CreateTags_402656556; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
                                                                                         ## 
  let valid = call_402656579.validator(path, query, header, formData, body, _)
  let scheme = call_402656579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656579.makeUrl(scheme.get, call_402656579.host, call_402656579.base,
                                   call_402656579.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656579, uri, valid, _)

proc call*(call_402656580: Call_CreateTags_402656556; FileSystemId: string;
           body: JsonNode): Recallable =
  ## createTags
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## tags 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## modify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## (String). 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## This 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## operation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## modifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## tags 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## only, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## system.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var path_402656581 = newJObject()
  var body_402656582 = newJObject()
  add(path_402656581, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_402656582 = body
  result = call_402656580.call(path_402656581, nil, nil, nil, body_402656582)

var createTags* = Call_CreateTags_402656556(name: "createTags",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/create-tags/{FileSystemId}",
    validator: validate_CreateTags_402656557, base: "/",
    makeUrl: url_CreateTags_402656558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPoint_402656583 = ref object of OpenApiRestCall_402656044
proc url_DeleteAccessPoint_402656585(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPoint_402656584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656586 = path.getOrDefault("AccessPointId")
  valid_402656586 = validateParameter(valid_402656586, JString, required = true,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "AccessPointId", valid_402656586
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656587 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Security-Token", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Signature")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Signature", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Algorithm", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Date")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Date", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Credential")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Credential", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656594: Call_DeleteAccessPoint_402656583;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified access point. After deletion is complete, new clients can no longer connect to the access points. Clients connected to the access point at the time of deletion will continue to function until they terminate their connection.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteAccessPoint</code> action.</p>
                                                                                         ## 
  let valid = call_402656594.validator(path, query, header, formData, body, _)
  let scheme = call_402656594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656594.makeUrl(scheme.get, call_402656594.host, call_402656594.base,
                                   call_402656594.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656594, uri, valid, _)

proc call*(call_402656595: Call_DeleteAccessPoint_402656583;
           AccessPointId: string): Recallable =
  ## deleteAccessPoint
  ## <p>Deletes the specified access point. After deletion is complete, new clients can no longer connect to the access points. Clients connected to the access point at the time of deletion will continue to function until they terminate their connection.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteAccessPoint</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                              ## AccessPointId: string (required)
                                                                                                                                                                                                                                                                                                                                                                              ##                
                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                              ## access 
                                                                                                                                                                                                                                                                                                                                                                              ## point 
                                                                                                                                                                                                                                                                                                                                                                              ## that 
                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                              ## want 
                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                              ## delete.
  var path_402656596 = newJObject()
  add(path_402656596, "AccessPointId", newJString(AccessPointId))
  result = call_402656595.call(path_402656596, nil, nil, nil, nil)

var deleteAccessPoint* = Call_DeleteAccessPoint_402656583(
    name: "deleteAccessPoint", meth: HttpMethod.HttpDelete,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/access-points/{AccessPointId}",
    validator: validate_DeleteAccessPoint_402656584, base: "/",
    makeUrl: url_DeleteAccessPoint_402656585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_402656597 = ref object of OpenApiRestCall_402656044
proc url_UpdateFileSystem_402656599(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFileSystem_402656598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656600 = path.getOrDefault("FileSystemId")
  valid_402656600 = validateParameter(valid_402656600, JString, required = true,
                                      default = nil)
  if valid_402656600 != nil:
    section.add "FileSystemId", valid_402656600
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656601 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Security-Token", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Signature")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Signature", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Algorithm", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Date")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Date", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Credential")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Credential", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656609: Call_UpdateFileSystem_402656597;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
                                                                                         ## 
  let valid = call_402656609.validator(path, query, header, formData, body, _)
  let scheme = call_402656609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656609.makeUrl(scheme.get, call_402656609.host, call_402656609.base,
                                   call_402656609.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656609, uri, valid, _)

proc call*(call_402656610: Call_UpdateFileSystem_402656597;
           FileSystemId: string; body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ##   
                                                                                                    ## FileSystemId: string (required)
                                                                                                    ##               
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## ID 
                                                                                                    ## of 
                                                                                                    ## the 
                                                                                                    ## file 
                                                                                                    ## system 
                                                                                                    ## that 
                                                                                                    ## you 
                                                                                                    ## want 
                                                                                                    ## to 
                                                                                                    ## update.
  ##   
                                                                                                              ## body: JObject (required)
  var path_402656611 = newJObject()
  var body_402656612 = newJObject()
  add(path_402656611, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_402656612 = body
  result = call_402656610.call(path_402656611, nil, nil, nil, body_402656612)

var updateFileSystem* = Call_UpdateFileSystem_402656597(
    name: "updateFileSystem", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_UpdateFileSystem_402656598, base: "/",
    makeUrl: url_UpdateFileSystem_402656599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_402656613 = ref object of OpenApiRestCall_402656044
proc url_DeleteFileSystem_402656615(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFileSystem_402656614(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656616 = path.getOrDefault("FileSystemId")
  valid_402656616 = validateParameter(valid_402656616, JString, required = true,
                                      default = nil)
  if valid_402656616 != nil:
    section.add "FileSystemId", valid_402656616
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656624: Call_DeleteFileSystem_402656613;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
                                                                                         ## 
  let valid = call_402656624.validator(path, query, header, formData, body, _)
  let scheme = call_402656624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656624.makeUrl(scheme.get, call_402656624.host, call_402656624.base,
                                   call_402656624.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656624, uri, valid, _)

proc call*(call_402656625: Call_DeleteFileSystem_402656613; FileSystemId: string): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## delete.
  var path_402656626 = newJObject()
  add(path_402656626, "FileSystemId", newJString(FileSystemId))
  result = call_402656625.call(path_402656626, nil, nil, nil, nil)

var deleteFileSystem* = Call_DeleteFileSystem_402656613(
    name: "deleteFileSystem", meth: HttpMethod.HttpDelete,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_DeleteFileSystem_402656614, base: "/",
    makeUrl: url_DeleteFileSystem_402656615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFileSystemPolicy_402656641 = ref object of OpenApiRestCall_402656044
proc url_PutFileSystemPolicy_402656643(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFileSystemPolicy_402656642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656644 = path.getOrDefault("FileSystemId")
  valid_402656644 = validateParameter(valid_402656644, JString, required = true,
                                      default = nil)
  if valid_402656644 != nil:
    section.add "FileSystemId", valid_402656644
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656645 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Security-Token", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Signature")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Signature", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Algorithm", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Date")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Date", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Credential")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Credential", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656653: Call_PutFileSystemPolicy_402656641;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Applies an Amazon EFS <code>FileSystemPolicy</code> to an Amazon EFS file system. A file system policy is an IAM resource-based policy and can contain multiple policy statements. A file system always has exactly one file system policy, which can be the default policy or an explicit policy set or updated using this API operation. When an explicit policy is set, it overrides the default policy. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>. </p> <p>This operation requires permissions for the <code>elasticfilesystem:PutFileSystemPolicy</code> action.</p>
                                                                                         ## 
  let valid = call_402656653.validator(path, query, header, formData, body, _)
  let scheme = call_402656653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656653.makeUrl(scheme.get, call_402656653.host, call_402656653.base,
                                   call_402656653.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656653, uri, valid, _)

proc call*(call_402656654: Call_PutFileSystemPolicy_402656641;
           FileSystemId: string; body: JsonNode): Recallable =
  ## putFileSystemPolicy
  ## <p>Applies an Amazon EFS <code>FileSystemPolicy</code> to an Amazon EFS file system. A file system policy is an IAM resource-based policy and can contain multiple policy statements. A file system always has exactly one file system policy, which can be the default policy or an explicit policy set or updated using this API operation. When an explicit policy is set, it overrides the default policy. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>. </p> <p>This operation requires permissions for the <code>elasticfilesystem:PutFileSystemPolicy</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## EFS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## update 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## <code>FileSystemPolicy</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## for.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var path_402656655 = newJObject()
  var body_402656656 = newJObject()
  add(path_402656655, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_402656656 = body
  result = call_402656654.call(path_402656655, nil, nil, nil, body_402656656)

var putFileSystemPolicy* = Call_PutFileSystemPolicy_402656641(
    name: "putFileSystemPolicy", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/policy",
    validator: validate_PutFileSystemPolicy_402656642, base: "/",
    makeUrl: url_PutFileSystemPolicy_402656643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystemPolicy_402656627 = ref object of OpenApiRestCall_402656044
proc url_DescribeFileSystemPolicy_402656629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFileSystemPolicy_402656628(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656630 = path.getOrDefault("FileSystemId")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "FileSystemId", valid_402656630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656638: Call_DescribeFileSystemPolicy_402656627;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the <code>FileSystemPolicy</code> for the specified EFS file system.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystemPolicy</code> action.</p>
                                                                                         ## 
  let valid = call_402656638.validator(path, query, header, formData, body, _)
  let scheme = call_402656638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656638.makeUrl(scheme.get, call_402656638.host, call_402656638.base,
                                   call_402656638.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656638, uri, valid, _)

proc call*(call_402656639: Call_DescribeFileSystemPolicy_402656627;
           FileSystemId: string): Recallable =
  ## describeFileSystemPolicy
  ## <p>Returns the <code>FileSystemPolicy</code> for the specified EFS file system.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystemPolicy</code> action.</p>
  ##   
                                                                                                                                                                                                           ## FileSystemId: string (required)
                                                                                                                                                                                                           ##               
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## Specifies 
                                                                                                                                                                                                           ## which 
                                                                                                                                                                                                           ## EFS 
                                                                                                                                                                                                           ## file 
                                                                                                                                                                                                           ## system 
                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                           ## retrieve 
                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                           ## <code>FileSystemPolicy</code> 
                                                                                                                                                                                                           ## for.
  var path_402656640 = newJObject()
  add(path_402656640, "FileSystemId", newJString(FileSystemId))
  result = call_402656639.call(path_402656640, nil, nil, nil, nil)

var describeFileSystemPolicy* = Call_DescribeFileSystemPolicy_402656627(
    name: "describeFileSystemPolicy", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/policy",
    validator: validate_DescribeFileSystemPolicy_402656628, base: "/",
    makeUrl: url_DescribeFileSystemPolicy_402656629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystemPolicy_402656657 = ref object of OpenApiRestCall_402656044
proc url_DeleteFileSystemPolicy_402656659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFileSystemPolicy_402656658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656660 = path.getOrDefault("FileSystemId")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "FileSystemId", valid_402656660
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656661 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Security-Token", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Signature")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Signature", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Algorithm", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Date")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Date", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Credential")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Credential", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656668: Call_DeleteFileSystemPolicy_402656657;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the <code>FileSystemPolicy</code> for the specified file system. The default <code>FileSystemPolicy</code> goes into effect once the existing policy is deleted. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystemPolicy</code> action.</p>
                                                                                         ## 
  let valid = call_402656668.validator(path, query, header, formData, body, _)
  let scheme = call_402656668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656668.makeUrl(scheme.get, call_402656668.host, call_402656668.base,
                                   call_402656668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656668, uri, valid, _)

proc call*(call_402656669: Call_DeleteFileSystemPolicy_402656657;
           FileSystemId: string): Recallable =
  ## deleteFileSystemPolicy
  ## <p>Deletes the <code>FileSystemPolicy</code> for the specified file system. The default <code>FileSystemPolicy</code> goes into effect once the existing policy is deleted. For more information about the default file system policy, see <a href="https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html">Using Resource-based Policies with EFS</a>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystemPolicy</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## EFS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## delete 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <code>FileSystemPolicy</code>.
  var path_402656670 = newJObject()
  add(path_402656670, "FileSystemId", newJString(FileSystemId))
  result = call_402656669.call(path_402656670, nil, nil, nil, nil)

var deleteFileSystemPolicy* = Call_DeleteFileSystemPolicy_402656657(
    name: "deleteFileSystemPolicy", meth: HttpMethod.HttpDelete,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/policy",
    validator: validate_DeleteFileSystemPolicy_402656658, base: "/",
    makeUrl: url_DeleteFileSystemPolicy_402656659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMountTarget_402656671 = ref object of OpenApiRestCall_402656044
proc url_DeleteMountTarget_402656673(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMountTarget_402656672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656674 = path.getOrDefault("MountTargetId")
  valid_402656674 = validateParameter(valid_402656674, JString, required = true,
                                      default = nil)
  if valid_402656674 != nil:
    section.add "MountTargetId", valid_402656674
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656675 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Security-Token", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Signature")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Signature", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Algorithm", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Date")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Date", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Credential")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Credential", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656682: Call_DeleteMountTarget_402656671;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656682.validator(path, query, header, formData, body, _)
  let scheme = call_402656682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656682.makeUrl(scheme.get, call_402656682.host, call_402656682.base,
                                   call_402656682.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656682, uri, valid, _)

proc call*(call_402656683: Call_DeleteMountTarget_402656671;
           MountTargetId: string): Recallable =
  ## deleteMountTarget
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## MountTargetId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## target 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## delete 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## (String).
  var path_402656684 = newJObject()
  add(path_402656684, "MountTargetId", newJString(MountTargetId))
  result = call_402656683.call(path_402656684, nil, nil, nil, nil)

var deleteMountTarget* = Call_DeleteMountTarget_402656671(
    name: "deleteMountTarget", meth: HttpMethod.HttpDelete,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}",
    validator: validate_DeleteMountTarget_402656672, base: "/",
    makeUrl: url_DeleteMountTarget_402656673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_402656685 = ref object of OpenApiRestCall_402656044
proc url_DeleteTags_402656687(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_402656686(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656688 = path.getOrDefault("FileSystemId")
  valid_402656688 = validateParameter(valid_402656688, JString, required = true,
                                      default = nil)
  if valid_402656688 != nil:
    section.add "FileSystemId", valid_402656688
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656689 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Security-Token", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Signature")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Signature", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Algorithm", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Date")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Date", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Credential")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Credential", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656697: Call_DeleteTags_402656685; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
                                                                                         ## 
  let valid = call_402656697.validator(path, query, header, formData, body, _)
  let scheme = call_402656697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656697.makeUrl(scheme.get, call_402656697.host, call_402656697.base,
                                   call_402656697.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656697, uri, valid, _)

proc call*(call_402656698: Call_DeleteTags_402656685; FileSystemId: string;
           body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## tags 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## delete 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## (String).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var path_402656699 = newJObject()
  var body_402656700 = newJObject()
  add(path_402656699, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_402656700 = body
  result = call_402656698.call(path_402656699, nil, nil, nil, body_402656700)

var deleteTags* = Call_DeleteTags_402656685(name: "deleteTags",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/delete-tags/{FileSystemId}",
    validator: validate_DeleteTags_402656686, base: "/",
    makeUrl: url_DeleteTags_402656687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleConfiguration_402656715 = ref object of OpenApiRestCall_402656044
proc url_PutLifecycleConfiguration_402656717(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutLifecycleConfiguration_402656716(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656718 = path.getOrDefault("FileSystemId")
  valid_402656718 = validateParameter(valid_402656718, JString, required = true,
                                      default = nil)
  if valid_402656718 != nil:
    section.add "FileSystemId", valid_402656718
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656719 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Security-Token", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Signature")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Signature", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Algorithm", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Date")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Date", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Credential")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Credential", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656727: Call_PutLifecycleConfiguration_402656715;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
                                                                                         ## 
  let valid = call_402656727.validator(path, query, header, formData, body, _)
  let scheme = call_402656727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656727.makeUrl(scheme.get, call_402656727.host, call_402656727.base,
                                   call_402656727.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656727, uri, valid, _)

proc call*(call_402656728: Call_PutLifecycleConfiguration_402656715;
           FileSystemId: string; body: JsonNode): Recallable =
  ## putLifecycleConfiguration
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## creating 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## <code>LifecycleConfiguration</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## object 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## (String).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var path_402656729 = newJObject()
  var body_402656730 = newJObject()
  add(path_402656729, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_402656730 = body
  result = call_402656728.call(path_402656729, nil, nil, nil, body_402656730)

var putLifecycleConfiguration* = Call_PutLifecycleConfiguration_402656715(
    name: "putLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_PutLifecycleConfiguration_402656716, base: "/",
    makeUrl: url_PutLifecycleConfiguration_402656717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLifecycleConfiguration_402656701 = ref object of OpenApiRestCall_402656044
proc url_DescribeLifecycleConfiguration_402656703(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeLifecycleConfiguration_402656702(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656704 = path.getOrDefault("FileSystemId")
  valid_402656704 = validateParameter(valid_402656704, JString, required = true,
                                      default = nil)
  if valid_402656704 != nil:
    section.add "FileSystemId", valid_402656704
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656705 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Security-Token", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Signature")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Signature", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Algorithm", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Date")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Date", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Credential")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Credential", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656712: Call_DescribeLifecycleConfiguration_402656701;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
                                                                                         ## 
  let valid = call_402656712.validator(path, query, header, formData, body, _)
  let scheme = call_402656712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656712.makeUrl(scheme.get, call_402656712.host, call_402656712.base,
                                   call_402656712.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656712, uri, valid, _)

proc call*(call_402656713: Call_DescribeLifecycleConfiguration_402656701;
           FileSystemId: string): Recallable =
  ## describeLifecycleConfiguration
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## file 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## system 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## <code>LifecycleConfiguration</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## object 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## (String).
  var path_402656714 = newJObject()
  add(path_402656714, "FileSystemId", newJString(FileSystemId))
  result = call_402656713.call(path_402656714, nil, nil, nil, nil)

var describeLifecycleConfiguration* = Call_DescribeLifecycleConfiguration_402656701(
    name: "describeLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_DescribeLifecycleConfiguration_402656702, base: "/",
    makeUrl: url_DescribeLifecycleConfiguration_402656703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyMountTargetSecurityGroups_402656745 = ref object of OpenApiRestCall_402656044
proc url_ModifyMountTargetSecurityGroups_402656747(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ModifyMountTargetSecurityGroups_402656746(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656748 = path.getOrDefault("MountTargetId")
  valid_402656748 = validateParameter(valid_402656748, JString, required = true,
                                      default = nil)
  if valid_402656748 != nil:
    section.add "MountTargetId", valid_402656748
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656749 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Security-Token", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Signature")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Signature", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Algorithm", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Date")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Date", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Credential")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Credential", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656757: Call_ModifyMountTargetSecurityGroups_402656745;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656757.validator(path, query, header, formData, body, _)
  let scheme = call_402656757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656757.makeUrl(scheme.get, call_402656757.host, call_402656757.base,
                                   call_402656757.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656757, uri, valid, _)

proc call*(call_402656758: Call_ModifyMountTargetSecurityGroups_402656745;
           body: JsonNode; MountTargetId: string): Recallable =
  ## modifyMountTargetSecurityGroups
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## MountTargetId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## target 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## security 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## modify.
  var path_402656759 = newJObject()
  var body_402656760 = newJObject()
  if body != nil:
    body_402656760 = body
  add(path_402656759, "MountTargetId", newJString(MountTargetId))
  result = call_402656758.call(path_402656759, nil, nil, nil, body_402656760)

var modifyMountTargetSecurityGroups* = Call_ModifyMountTargetSecurityGroups_402656745(
    name: "modifyMountTargetSecurityGroups", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_ModifyMountTargetSecurityGroups_402656746, base: "/",
    makeUrl: url_ModifyMountTargetSecurityGroups_402656747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargetSecurityGroups_402656731 = ref object of OpenApiRestCall_402656044
proc url_DescribeMountTargetSecurityGroups_402656733(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMountTargetSecurityGroups_402656732(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656734 = path.getOrDefault("MountTargetId")
  valid_402656734 = validateParameter(valid_402656734, JString, required = true,
                                      default = nil)
  if valid_402656734 != nil:
    section.add "MountTargetId", valid_402656734
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656735 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Security-Token", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Signature")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Signature", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Algorithm", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Date")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Date", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Credential")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Credential", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656742: Call_DescribeMountTargetSecurityGroups_402656731;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656742.validator(path, query, header, formData, body, _)
  let scheme = call_402656742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656742.makeUrl(scheme.get, call_402656742.host, call_402656742.base,
                                   call_402656742.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656742, uri, valid, _)

proc call*(call_402656743: Call_DescribeMountTargetSecurityGroups_402656731;
           MountTargetId: string): Recallable =
  ## describeMountTargetSecurityGroups
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MountTargetId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## mount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## target 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## security 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## retrieve.
  var path_402656744 = newJObject()
  add(path_402656744, "MountTargetId", newJString(MountTargetId))
  result = call_402656743.call(path_402656744, nil, nil, nil, nil)

var describeMountTargetSecurityGroups* = Call_DescribeMountTargetSecurityGroups_402656731(
    name: "describeMountTargetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_DescribeMountTargetSecurityGroups_402656732, base: "/",
    makeUrl: url_DescribeMountTargetSecurityGroups_402656733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_402656761 = ref object of OpenApiRestCall_402656044
proc url_DescribeTags_402656763(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTags_402656762(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656764 = path.getOrDefault("FileSystemId")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true,
                                      default = nil)
  if valid_402656764 != nil:
    section.add "FileSystemId", valid_402656764
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   
                                                                                                                                                                                                                                                ## MaxItems: JInt
                                                                                                                                                                                                                                                ##           
                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                ## (Optional) 
                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                ## maximum 
                                                                                                                                                                                                                                                ## number 
                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                ## file 
                                                                                                                                                                                                                                                ## system 
                                                                                                                                                                                                                                                ## tags 
                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                ## return 
                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                ## response. 
                                                                                                                                                                                                                                                ## Currently, 
                                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                                ## number 
                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                ## automatically 
                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                ## 100, 
                                                                                                                                                                                                                                                ## and 
                                                                                                                                                                                                                                                ## other 
                                                                                                                                                                                                                                                ## values 
                                                                                                                                                                                                                                                ## are 
                                                                                                                                                                                                                                                ## ignored. 
                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                ## paginated 
                                                                                                                                                                                                                                                ## at 
                                                                                                                                                                                                                                                ## 100 
                                                                                                                                                                                                                                                ## per 
                                                                                                                                                                                                                                                ## page 
                                                                                                                                                                                                                                                ## if 
                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                ## have 
                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                ## than 
                                                                                                                                                                                                                                                ## 100 
                                                                                                                                                                                                                                                ## tags.
  section = newJObject()
  var valid_402656765 = query.getOrDefault("Marker")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "Marker", valid_402656765
  var valid_402656766 = query.getOrDefault("MaxItems")
  valid_402656766 = validateParameter(valid_402656766, JInt, required = false,
                                      default = nil)
  if valid_402656766 != nil:
    section.add "MaxItems", valid_402656766
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656767 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Security-Token", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Signature")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Signature", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Algorithm", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Date")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Date", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Credential")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Credential", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656774: Call_DescribeTags_402656761; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
                                                                                         ## 
  let valid = call_402656774.validator(path, query, header, formData, body, _)
  let scheme = call_402656774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656774.makeUrl(scheme.get, call_402656774.host, call_402656774.base,
                                   call_402656774.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656774, uri, valid, _)

proc call*(call_402656775: Call_DescribeTags_402656761; FileSystemId: string;
           Marker: string = ""; MaxItems: int = 0): Recallable =
  ## describeTags
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                               ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                               ##         
                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                               ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                               ## An 
                                                                                                                                                                                                                                                                                                                                                                               ## opaque 
                                                                                                                                                                                                                                                                                                                                                                               ## pagination 
                                                                                                                                                                                                                                                                                                                                                                               ## token 
                                                                                                                                                                                                                                                                                                                                                                               ## returned 
                                                                                                                                                                                                                                                                                                                                                                               ## from 
                                                                                                                                                                                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                                                                                                                                                                                               ## previous 
                                                                                                                                                                                                                                                                                                                                                                               ## <code>DescribeTags</code> 
                                                                                                                                                                                                                                                                                                                                                                               ## operation 
                                                                                                                                                                                                                                                                                                                                                                               ## (String). 
                                                                                                                                                                                                                                                                                                                                                                               ## If 
                                                                                                                                                                                                                                                                                                                                                                               ## present, 
                                                                                                                                                                                                                                                                                                                                                                               ## it 
                                                                                                                                                                                                                                                                                                                                                                               ## specifies 
                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                               ## continue 
                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                               ## list 
                                                                                                                                                                                                                                                                                                                                                                               ## from 
                                                                                                                                                                                                                                                                                                                                                                               ## where 
                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                               ## previous 
                                                                                                                                                                                                                                                                                                                                                                               ## call 
                                                                                                                                                                                                                                                                                                                                                                               ## left 
                                                                                                                                                                                                                                                                                                                                                                               ## off.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                      ## FileSystemId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                      ##               
                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                      ## ID 
                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                      ## file 
                                                                                                                                                                                                                                                                                                                                                                                      ## system 
                                                                                                                                                                                                                                                                                                                                                                                      ## whose 
                                                                                                                                                                                                                                                                                                                                                                                      ## tag 
                                                                                                                                                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                      ## want 
                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                      ## retrieve.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                  ## MaxItems: int
                                                                                                                                                                                                                                                                                                                                                                                                  ##           
                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                  ## (Optional) 
                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                  ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                  ## number 
                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                  ## file 
                                                                                                                                                                                                                                                                                                                                                                                                  ## system 
                                                                                                                                                                                                                                                                                                                                                                                                  ## tags 
                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                  ## return 
                                                                                                                                                                                                                                                                                                                                                                                                  ## in 
                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                  ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                  ## Currently, 
                                                                                                                                                                                                                                                                                                                                                                                                  ## this 
                                                                                                                                                                                                                                                                                                                                                                                                  ## number 
                                                                                                                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                                                                                                                  ## automatically 
                                                                                                                                                                                                                                                                                                                                                                                                  ## set 
                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                  ## 100, 
                                                                                                                                                                                                                                                                                                                                                                                                  ## and 
                                                                                                                                                                                                                                                                                                                                                                                                  ## other 
                                                                                                                                                                                                                                                                                                                                                                                                  ## values 
                                                                                                                                                                                                                                                                                                                                                                                                  ## are 
                                                                                                                                                                                                                                                                                                                                                                                                  ## ignored. 
                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                  ## response 
                                                                                                                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                                                                                                                  ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                  ## at 
                                                                                                                                                                                                                                                                                                                                                                                                  ## 100 
                                                                                                                                                                                                                                                                                                                                                                                                  ## per 
                                                                                                                                                                                                                                                                                                                                                                                                  ## page 
                                                                                                                                                                                                                                                                                                                                                                                                  ## if 
                                                                                                                                                                                                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                                                                                                                                                                                                  ## have 
                                                                                                                                                                                                                                                                                                                                                                                                  ## more 
                                                                                                                                                                                                                                                                                                                                                                                                  ## than 
                                                                                                                                                                                                                                                                                                                                                                                                  ## 100 
                                                                                                                                                                                                                                                                                                                                                                                                  ## tags.
  var path_402656776 = newJObject()
  var query_402656777 = newJObject()
  add(query_402656777, "Marker", newJString(Marker))
  add(path_402656776, "FileSystemId", newJString(FileSystemId))
  add(query_402656777, "MaxItems", newJInt(MaxItems))
  result = call_402656775.call(path_402656776, query_402656777, nil, nil, nil)

var describeTags* = Call_DescribeTags_402656761(name: "describeTags",
    meth: HttpMethod.HttpGet, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/tags/{FileSystemId}/", validator: validate_DescribeTags_402656762,
    base: "/", makeUrl: url_DescribeTags_402656763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656795 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656797(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656796(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656798 = path.getOrDefault("ResourceId")
  valid_402656798 = validateParameter(valid_402656798, JString, required = true,
                                      default = nil)
  if valid_402656798 != nil:
    section.add "ResourceId", valid_402656798
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656799 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Security-Token", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Signature")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Signature", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Algorithm", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Date")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Date", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Credential")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Credential", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656807: Call_TagResource_402656795; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a tag for an EFS resource. You can create tags for EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:TagResource</code> action.</p>
                                                                                         ## 
  let valid = call_402656807.validator(path, query, header, formData, body, _)
  let scheme = call_402656807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656807.makeUrl(scheme.get, call_402656807.host, call_402656807.base,
                                   call_402656807.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656807, uri, valid, _)

proc call*(call_402656808: Call_TagResource_402656795; ResourceId: string;
           body: JsonNode): Recallable =
  ## tagResource
  ## <p>Creates a tag for an EFS resource. You can create tags for EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:TagResource</code> action.</p>
  ##   
                                                                                                                                                                                                                                         ## ResourceId: string (required)
                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                         ## ID 
                                                                                                                                                                                                                                         ## specifying 
                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                         ## EFS 
                                                                                                                                                                                                                                         ## resource 
                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                         ## want 
                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                         ## create 
                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                         ## tag 
                                                                                                                                                                                                                                         ## for. 
  ##   
                                                                                                                                                                                                                                                 ## body: JObject (required)
  var path_402656809 = newJObject()
  var body_402656810 = newJObject()
  add(path_402656809, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_402656810 = body
  result = call_402656808.call(path_402656809, nil, nil, nil, body_402656810)

var tagResource* = Call_TagResource_402656795(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/resource-tags/{ResourceId}",
    validator: validate_TagResource_402656796, base: "/",
    makeUrl: url_TagResource_402656797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656778 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656780(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656779(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656781 = path.getOrDefault("ResourceId")
  valid_402656781 = validateParameter(valid_402656781, JString, required = true,
                                      default = nil)
  if valid_402656781 != nil:
    section.add "ResourceId", valid_402656781
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : (Optional) Specifies the maximum number of tag objects to return in the response. The default value is 100.
  ##   
                                                                                                                                                              ## NextToken: JString
                                                                                                                                                              ##            
                                                                                                                                                              ## : 
                                                                                                                                                              ## You 
                                                                                                                                                              ## can 
                                                                                                                                                              ## use 
                                                                                                                                                              ## <code>NextToken</code> 
                                                                                                                                                              ## in 
                                                                                                                                                              ## a 
                                                                                                                                                              ## subsequent 
                                                                                                                                                              ## request 
                                                                                                                                                              ## to 
                                                                                                                                                              ## fetch 
                                                                                                                                                              ## the 
                                                                                                                                                              ## next 
                                                                                                                                                              ## page 
                                                                                                                                                              ## of 
                                                                                                                                                              ## access 
                                                                                                                                                              ## point 
                                                                                                                                                              ## descriptions 
                                                                                                                                                              ## if 
                                                                                                                                                              ## the 
                                                                                                                                                              ## response 
                                                                                                                                                              ## payload 
                                                                                                                                                              ## was 
                                                                                                                                                              ## paginated.
  section = newJObject()
  var valid_402656782 = query.getOrDefault("MaxResults")
  valid_402656782 = validateParameter(valid_402656782, JInt, required = false,
                                      default = nil)
  if valid_402656782 != nil:
    section.add "MaxResults", valid_402656782
  var valid_402656783 = query.getOrDefault("NextToken")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "NextToken", valid_402656783
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656784 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Security-Token", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Signature")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Signature", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Algorithm", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Date")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Date", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Credential")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Credential", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656791: Call_ListTagsForResource_402656778;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all tags for a top-level EFS resource. You must provide the ID of the resource that you want to retrieve the tags for.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
                                                                                         ## 
  let valid = call_402656791.validator(path, query, header, formData, body, _)
  let scheme = call_402656791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656791.makeUrl(scheme.get, call_402656791.host, call_402656791.base,
                                   call_402656791.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656791, uri, valid, _)

proc call*(call_402656792: Call_ListTagsForResource_402656778;
           ResourceId: string; MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## <p>Lists all tags for a top-level EFS resource. You must provide the ID of the resource that you want to retrieve the tags for.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeAccessPoints</code> action.</p>
  ##   
                                                                                                                                                                                                                                                       ## ResourceId: string (required)
                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                       ## Specifies 
                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                       ## EFS 
                                                                                                                                                                                                                                                       ## resource 
                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                       ## retrieve 
                                                                                                                                                                                                                                                       ## tags 
                                                                                                                                                                                                                                                       ## for. 
                                                                                                                                                                                                                                                       ## You 
                                                                                                                                                                                                                                                       ## can 
                                                                                                                                                                                                                                                       ## retrieve 
                                                                                                                                                                                                                                                       ## tags 
                                                                                                                                                                                                                                                       ## for 
                                                                                                                                                                                                                                                       ## EFS 
                                                                                                                                                                                                                                                       ## file 
                                                                                                                                                                                                                                                       ## systems 
                                                                                                                                                                                                                                                       ## and 
                                                                                                                                                                                                                                                       ## access 
                                                                                                                                                                                                                                                       ## points 
                                                                                                                                                                                                                                                       ## using 
                                                                                                                                                                                                                                                       ## this 
                                                                                                                                                                                                                                                       ## API 
                                                                                                                                                                                                                                                       ## endpoint.
  ##   
                                                                                                                                                                                                                                                                   ## MaxResults: int
                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                   ## (Optional) 
                                                                                                                                                                                                                                                                   ## Specifies 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## maximum 
                                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                   ## tag 
                                                                                                                                                                                                                                                                   ## objects 
                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                   ## return 
                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## response. 
                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                   ## default 
                                                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                                   ## 100.
  ##   
                                                                                                                                                                                                                                                                          ## NextToken: string
                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                          ## You 
                                                                                                                                                                                                                                                                          ## can 
                                                                                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                                                                                          ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                          ## subsequent 
                                                                                                                                                                                                                                                                          ## request 
                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                          ## fetch 
                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                          ## next 
                                                                                                                                                                                                                                                                          ## page 
                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                          ## access 
                                                                                                                                                                                                                                                                          ## point 
                                                                                                                                                                                                                                                                          ## descriptions 
                                                                                                                                                                                                                                                                          ## if 
                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                                                                                          ## payload 
                                                                                                                                                                                                                                                                          ## was 
                                                                                                                                                                                                                                                                          ## paginated.
  var path_402656793 = newJObject()
  var query_402656794 = newJObject()
  add(path_402656793, "ResourceId", newJString(ResourceId))
  add(query_402656794, "MaxResults", newJInt(MaxResults))
  add(query_402656794, "NextToken", newJString(NextToken))
  result = call_402656792.call(path_402656793, query_402656794, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656778(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/resource-tags/{ResourceId}",
    validator: validate_ListTagsForResource_402656779, base: "/",
    makeUrl: url_ListTagsForResource_402656780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656811 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656813(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656812(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656814 = path.getOrDefault("ResourceId")
  valid_402656814 = validateParameter(valid_402656814, JString, required = true,
                                      default = nil)
  if valid_402656814 != nil:
    section.add "ResourceId", valid_402656814
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656815 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Security-Token", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Signature")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Signature", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Algorithm", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Date")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Date", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Credential")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Credential", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656823: Call_UntagResource_402656811; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes tags from an EFS resource. You can remove tags from EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:UntagResource</code> action.</p>
                                                                                         ## 
  let valid = call_402656823.validator(path, query, header, formData, body, _)
  let scheme = call_402656823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656823.makeUrl(scheme.get, call_402656823.host, call_402656823.base,
                                   call_402656823.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656823, uri, valid, _)

proc call*(call_402656824: Call_UntagResource_402656811; ResourceId: string;
           body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes tags from an EFS resource. You can remove tags from EFS file systems and access points using this API operation.</p> <p>This operation requires permissions for the <code>elasticfilesystem:UntagResource</code> action.</p>
  ##   
                                                                                                                                                                                                                                            ## ResourceId: string (required)
                                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## Specifies 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## EFS 
                                                                                                                                                                                                                                            ## resource 
                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## remove 
                                                                                                                                                                                                                                            ## tags 
                                                                                                                                                                                                                                            ## from.
  ##   
                                                                                                                                                                                                                                                    ## body: JObject (required)
  var path_402656825 = newJObject()
  var body_402656826 = newJObject()
  add(path_402656825, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_402656826 = body
  result = call_402656824.call(path_402656825, nil, nil, nil, body_402656826)

var untagResource* = Call_UntagResource_402656811(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/resource-tags/{ResourceId}",
    validator: validate_UntagResource_402656812, base: "/",
    makeUrl: url_UntagResource_402656813, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}