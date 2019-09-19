
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateFileSystem_601027 = ref object of OpenApiRestCall_600426
proc url_CreateFileSystem_601029(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFileSystem_601028(path: JsonNode; query: JsonNode;
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
  var valid_601030 = header.getOrDefault("X-Amz-Date")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Date", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Security-Token")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Security-Token", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Content-Sha256", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Algorithm")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Algorithm", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Signature")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Signature", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-SignedHeaders", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Credential")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Credential", valid_601036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601038: Call_CreateFileSystem_601027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ## 
  let valid = call_601038.validator(path, query, header, formData, body)
  let scheme = call_601038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601038.url(scheme.get, call_601038.host, call_601038.base,
                         call_601038.route, valid.getOrDefault("path"))
  result = hook(call_601038, url, valid)

proc call*(call_601039: Call_CreateFileSystem_601027; body: JsonNode): Recallable =
  ## createFileSystem
  ## <p>Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's AWS account with the specified creation token, this operation does the following:</p> <ul> <li> <p>Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state <code>creating</code>.</p> </li> <li> <p>Returns with the description of the created file system.</p> </li> </ul> <p>Otherwise, this operation returns a <code>FileSystemAlreadyExists</code> error with the ID of the existing file system.</p> <note> <p>For basic use cases, you can use a randomly generated UUID for the creation token.</p> </note> <p> The idempotent operation allows you to retry a <code>CreateFileSystem</code> call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the <code>FileSystemAlreadyExists</code> error.</p> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>creating</code>. You can check the file system creation status by calling the <a>DescribeFileSystems</a> operation, which among other things returns the file system state.</p> </note> <p>This operation also takes an optional <code>PerformanceMode</code> parameter that you choose for your file system. We recommend <code>generalPurpose</code> performance mode for most file systems. File systems using the <code>maxIO</code> performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html">Amazon EFS: Performance Modes</a>.</p> <p>After the file system is fully created, Amazon EFS sets its lifecycle state to <code>available</code>, at which point you can create one or more mount targets for the file system in your VPC. For more information, see <a>CreateMountTarget</a>. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p> This operation requires permissions for the <code>elasticfilesystem:CreateFileSystem</code> action. </p>
  ##   body: JObject (required)
  var body_601040 = newJObject()
  if body != nil:
    body_601040 = body
  result = call_601039.call(nil, nil, nil, nil, body_601040)

var createFileSystem* = Call_CreateFileSystem_601027(name: "createFileSystem",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems", validator: validate_CreateFileSystem_601028,
    base: "/", url: url_CreateFileSystem_601029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFileSystems_600768 = ref object of OpenApiRestCall_600426
proc url_DescribeFileSystems_600770(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFileSystems_600769(path: JsonNode; query: JsonNode;
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
  var valid_600882 = query.getOrDefault("FileSystemId")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "FileSystemId", valid_600882
  var valid_600883 = query.getOrDefault("Marker")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "Marker", valid_600883
  var valid_600884 = query.getOrDefault("MaxItems")
  valid_600884 = validateParameter(valid_600884, JInt, required = false, default = nil)
  if valid_600884 != nil:
    section.add "MaxItems", valid_600884
  var valid_600885 = query.getOrDefault("CreationToken")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "CreationToken", valid_600885
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
  var valid_600886 = header.getOrDefault("X-Amz-Date")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Date", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Security-Token")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Security-Token", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Content-Sha256", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Algorithm")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Algorithm", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Signature")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Signature", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-SignedHeaders", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Credential")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Credential", valid_600892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600915: Call_DescribeFileSystems_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the description of a specific Amazon EFS file system if either the file system <code>CreationToken</code> or the <code>FileSystemId</code> is provided. Otherwise, it returns descriptions of all file systems owned by the caller's AWS account in the AWS Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxItems</code> parameter to limit the number of descriptions in a response. Currently, this number is automatically set to 10. If more file system descriptions remain, Amazon EFS returns a <code>NextMarker</code>, an opaque token, in the response. In this case, you should send a subsequent request with the <code>Marker</code> request parameter set to the value of <code>NextMarker</code>. </p> <p>To retrieve a list of your file system descriptions, this operation is used in an iterative process, where <code>DescribeFileSystems</code> is called first without the <code>Marker</code> and then the operation continues to call it with the <code>Marker</code> parameter set to the value of the <code>NextMarker</code> from the previous response until the response has no <code>NextMarker</code>. </p> <p> The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multi-call iteration is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeFileSystems</code> action. </p>
  ## 
  let valid = call_600915.validator(path, query, header, formData, body)
  let scheme = call_600915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600915.url(scheme.get, call_600915.host, call_600915.base,
                         call_600915.route, valid.getOrDefault("path"))
  result = hook(call_600915, url, valid)

proc call*(call_600986: Call_DescribeFileSystems_600768; FileSystemId: string = "";
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
  var query_600987 = newJObject()
  add(query_600987, "FileSystemId", newJString(FileSystemId))
  add(query_600987, "Marker", newJString(Marker))
  add(query_600987, "MaxItems", newJInt(MaxItems))
  add(query_600987, "CreationToken", newJString(CreationToken))
  result = call_600986.call(nil, query_600987, nil, nil, nil)

var describeFileSystems* = Call_DescribeFileSystems_600768(
    name: "describeFileSystems", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/file-systems",
    validator: validate_DescribeFileSystems_600769, base: "/",
    url: url_DescribeFileSystems_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMountTarget_601058 = ref object of OpenApiRestCall_600426
proc url_CreateMountTarget_601060(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMountTarget_601059(path: JsonNode; query: JsonNode;
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
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Content-Sha256", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Algorithm")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Algorithm", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601069: Call_CreateMountTarget_601058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_601069.validator(path, query, header, formData, body)
  let scheme = call_601069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601069.url(scheme.get, call_601069.host, call_601069.base,
                         call_601069.route, valid.getOrDefault("path"))
  result = hook(call_601069, url, valid)

proc call*(call_601070: Call_CreateMountTarget_601058; body: JsonNode): Recallable =
  ## createMountTarget
  ## <p>Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target.</p> <p>You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html">Amazon EFS: How it Works</a>. </p> <p>In the request, you also specify a file system ID for which you are creating the mount target and the file system's lifecycle state must be <code>available</code>. For more information, see <a>DescribeFileSystems</a>.</p> <p>In the request, you also provide a subnet ID, which determines the following:</p> <ul> <li> <p>VPC in which Amazon EFS creates the mount target</p> </li> <li> <p>Availability Zone in which Amazon EFS creates the mount target</p> </li> <li> <p>IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request)</p> </li> </ul> <p>After creating the mount target, Amazon EFS returns a response that includes, a <code>MountTargetId</code> and an <code>IpAddress</code>. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see <a href="https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation">How it Works: Implementation Overview</a>. </p> <p>Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements:</p> <ul> <li> <p>Must belong to the same VPC as the subnets of the existing mount targets</p> </li> <li> <p>Must not be in the same Availability Zone as any of the subnets of the existing mount targets</p> </li> </ul> <p>If the request satisfies the requirements, Amazon EFS does the following:</p> <ul> <li> <p>Creates a new mount target in the specified subnet.</p> </li> <li> <p>Also creates a new network interface in the subnet as follows:</p> <ul> <li> <p>If the request provides an <code>IpAddress</code>, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 <code>CreateNetworkInterface</code> call does when a request does not specify a primary private IP address).</p> </li> <li> <p>If the request provides <code>SecurityGroups</code>, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC.</p> </li> <li> <p>Assigns the description <code>Mount target <i>fsmt-id</i> for file system <i>fs-id</i> </code> where <code> <i>fsmt-id</i> </code> is the mount target ID, and <code> <i>fs-id</i> </code> is the <code>FileSystemId</code>.</p> </li> <li> <p>Sets the <code>requesterManaged</code> property of the network interface to <code>true</code>, and the <code>requesterId</code> value to <code>EFS</code>.</p> </li> </ul> <p>Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the <code>NetworkInterfaceId</code> field in the mount target's description to the network interface ID, and the <code>IpAddress</code> field to its address. If network interface creation fails, the entire <code>CreateMountTarget</code> operation fails.</p> </li> </ul> <note> <p>The <code>CreateMountTarget</code> call returns only after creating the network interface, but while the mount target state is still <code>creating</code>, you can check the mount target creation status by calling the <a>DescribeMountTargets</a> operation, which among other things returns the mount target state.</p> </note> <p>We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see <a href="http://aws.amazon.com/efs/">Amazon EFS</a>. In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. </p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:CreateMountTarget</code> </p> </li> </ul> <p>This operation also requires permissions for the following Amazon EC2 actions:</p> <ul> <li> <p> <code>ec2:DescribeSubnets</code> </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaces</code> </p> </li> <li> <p> <code>ec2:CreateNetworkInterface</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_601071 = newJObject()
  if body != nil:
    body_601071 = body
  result = call_601070.call(nil, nil, nil, nil, body_601071)

var createMountTarget* = Call_CreateMountTarget_601058(name: "createMountTarget",
    meth: HttpMethod.HttpPost, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets", validator: validate_CreateMountTarget_601059,
    base: "/", url: url_CreateMountTarget_601060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargets_601041 = ref object of OpenApiRestCall_600426
proc url_DescribeMountTargets_601043(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMountTargets_601042(path: JsonNode; query: JsonNode;
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
  var valid_601044 = query.getOrDefault("FileSystemId")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "FileSystemId", valid_601044
  var valid_601045 = query.getOrDefault("MountTargetId")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "MountTargetId", valid_601045
  var valid_601046 = query.getOrDefault("Marker")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "Marker", valid_601046
  var valid_601047 = query.getOrDefault("MaxItems")
  valid_601047 = validateParameter(valid_601047, JInt, required = false, default = nil)
  if valid_601047 != nil:
    section.add "MaxItems", valid_601047
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
  var valid_601048 = header.getOrDefault("X-Amz-Date")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Date", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Security-Token")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Security-Token", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Content-Sha256", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Algorithm")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Algorithm", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Signature")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Signature", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-SignedHeaders", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Credential")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Credential", valid_601054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_DescribeMountTargets_601041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeMountTargets</code> action, on either the file system ID that you specify in <code>FileSystemId</code>, or on the file system of the mount target that you specify in <code>MountTargetId</code>.</p>
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_DescribeMountTargets_601041;
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
  var query_601057 = newJObject()
  add(query_601057, "FileSystemId", newJString(FileSystemId))
  add(query_601057, "MountTargetId", newJString(MountTargetId))
  add(query_601057, "Marker", newJString(Marker))
  add(query_601057, "MaxItems", newJInt(MaxItems))
  result = call_601056.call(nil, query_601057, nil, nil, nil)

var describeMountTargets* = Call_DescribeMountTargets_601041(
    name: "describeMountTargets", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/mount-targets",
    validator: validate_DescribeMountTargets_601042, base: "/",
    url: url_DescribeMountTargets_601043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_601072 = ref object of OpenApiRestCall_600426
proc url_CreateTags_601074(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/create-tags/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateTags_601073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601089 = path.getOrDefault("FileSystemId")
  valid_601089 = validateParameter(valid_601089, JString, required = true,
                                 default = nil)
  if valid_601089 != nil:
    section.add "FileSystemId", valid_601089
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
  var valid_601090 = header.getOrDefault("X-Amz-Date")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Date", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Security-Token")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Security-Token", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Content-Sha256", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Algorithm")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Algorithm", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Signature")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Signature", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-SignedHeaders", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Credential")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Credential", valid_601096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601098: Call_CreateTags_601072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ## 
  let valid = call_601098.validator(path, query, header, formData, body)
  let scheme = call_601098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601098.url(scheme.get, call_601098.host, call_601098.base,
                         call_601098.route, valid.getOrDefault("path"))
  result = hook(call_601098, url, valid)

proc call*(call_601099: Call_CreateTags_601072; FileSystemId: string; body: JsonNode): Recallable =
  ## createTags
  ## <p>Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the <code>Name</code> tag to your file system, Amazon EFS returns it in the response to the <a>DescribeFileSystems</a> operation. </p> <p>This operation requires permission for the <code>elasticfilesystem:CreateTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to modify (String). This operation modifies the tags only, not the file system.
  ##   body: JObject (required)
  var path_601100 = newJObject()
  var body_601101 = newJObject()
  add(path_601100, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_601101 = body
  result = call_601099.call(path_601100, nil, nil, nil, body_601101)

var createTags* = Call_CreateTags_601072(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/create-tags/{FileSystemId}",
                                      validator: validate_CreateTags_601073,
                                      base: "/", url: url_CreateTags_601074,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFileSystem_601102 = ref object of OpenApiRestCall_600426
proc url_UpdateFileSystem_601104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFileSystem_601103(path: JsonNode; query: JsonNode;
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
  var valid_601105 = path.getOrDefault("FileSystemId")
  valid_601105 = validateParameter(valid_601105, JString, required = true,
                                 default = nil)
  if valid_601105 != nil:
    section.add "FileSystemId", valid_601105
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
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Content-Sha256", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Algorithm")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Algorithm", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Signature")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Signature", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-SignedHeaders", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Credential")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Credential", valid_601112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_UpdateFileSystem_601102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ## 
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"))
  result = hook(call_601114, url, valid)

proc call*(call_601115: Call_UpdateFileSystem_601102; FileSystemId: string;
          body: JsonNode): Recallable =
  ## updateFileSystem
  ## Updates the throughput mode or the amount of provisioned throughput of an existing file system.
  ##   FileSystemId: string (required)
  ##               : The ID of the file system that you want to update.
  ##   body: JObject (required)
  var path_601116 = newJObject()
  var body_601117 = newJObject()
  add(path_601116, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_601117 = body
  result = call_601115.call(path_601116, nil, nil, nil, body_601117)

var updateFileSystem* = Call_UpdateFileSystem_601102(name: "updateFileSystem",
    meth: HttpMethod.HttpPut, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_UpdateFileSystem_601103, base: "/",
    url: url_UpdateFileSystem_601104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFileSystem_601118 = ref object of OpenApiRestCall_600426
proc url_DeleteFileSystem_601120(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFileSystem_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = path.getOrDefault("FileSystemId")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "FileSystemId", valid_601121
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
  var valid_601122 = header.getOrDefault("X-Amz-Date")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Date", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Security-Token")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Security-Token", valid_601123
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
  if body != nil:
    result.add "body", body

proc call*(call_601129: Call_DeleteFileSystem_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ## 
  let valid = call_601129.validator(path, query, header, formData, body)
  let scheme = call_601129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601129.url(scheme.get, call_601129.host, call_601129.base,
                         call_601129.route, valid.getOrDefault("path"))
  result = hook(call_601129, url, valid)

proc call*(call_601130: Call_DeleteFileSystem_601118; FileSystemId: string): Recallable =
  ## deleteFileSystem
  ## <p>Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system.</p> <p> You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see <a>DescribeMountTargets</a> and <a>DeleteMountTarget</a>. </p> <note> <p>The <code>DeleteFileSystem</code> call returns while the file system state is still <code>deleting</code>. You can check the file system deletion status by calling the <a>DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the <a>DescribeFileSystems</a> returns a <code>404 FileSystemNotFound</code> error.</p> </note> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteFileSystem</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system you want to delete.
  var path_601131 = newJObject()
  add(path_601131, "FileSystemId", newJString(FileSystemId))
  result = call_601130.call(path_601131, nil, nil, nil, nil)

var deleteFileSystem* = Call_DeleteFileSystem_601118(name: "deleteFileSystem",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}",
    validator: validate_DeleteFileSystem_601119, base: "/",
    url: url_DeleteFileSystem_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMountTarget_601132 = ref object of OpenApiRestCall_600426
proc url_DeleteMountTarget_601134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "MountTargetId" in path, "`MountTargetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/mount-targets/"),
               (kind: VariableSegment, value: "MountTargetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMountTarget_601133(path: JsonNode; query: JsonNode;
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
  var valid_601135 = path.getOrDefault("MountTargetId")
  valid_601135 = validateParameter(valid_601135, JString, required = true,
                                 default = nil)
  if valid_601135 != nil:
    section.add "MountTargetId", valid_601135
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Content-Sha256", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Algorithm")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Algorithm", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Signature")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Signature", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-SignedHeaders", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Credential")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Credential", valid_601142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601143: Call_DeleteMountTarget_601132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ## 
  let valid = call_601143.validator(path, query, header, formData, body)
  let scheme = call_601143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601143.url(scheme.get, call_601143.host, call_601143.base,
                         call_601143.route, valid.getOrDefault("path"))
  result = hook(call_601143, url, valid)

proc call*(call_601144: Call_DeleteMountTarget_601132; MountTargetId: string): Recallable =
  ## deleteMountTarget
  ## <p>Deletes the specified mount target.</p> <p>This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target.</p> <p>This operation requires permissions for the following action on the file system:</p> <ul> <li> <p> <code>elasticfilesystem:DeleteMountTarget</code> </p> </li> </ul> <note> <p>The <code>DeleteMountTarget</code> call returns while the mount target state is still <code>deleting</code>. You can check the mount target deletion by calling the <a>DescribeMountTargets</a> operation, which returns a list of mount target descriptions for the given file system. </p> </note> <p>The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface:</p> <ul> <li> <p> <code>ec2:DeleteNetworkInterface</code> </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target to delete (String).
  var path_601145 = newJObject()
  add(path_601145, "MountTargetId", newJString(MountTargetId))
  result = call_601144.call(path_601145, nil, nil, nil, nil)

var deleteMountTarget* = Call_DeleteMountTarget_601132(name: "deleteMountTarget",
    meth: HttpMethod.HttpDelete, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}",
    validator: validate_DeleteMountTarget_601133, base: "/",
    url: url_DeleteMountTarget_601134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_601146 = ref object of OpenApiRestCall_600426
proc url_DeleteTags_601148(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/delete-tags/"),
               (kind: VariableSegment, value: "FileSystemId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteTags_601147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601149 = path.getOrDefault("FileSystemId")
  valid_601149 = validateParameter(valid_601149, JString, required = true,
                                 default = nil)
  if valid_601149 != nil:
    section.add "FileSystemId", valid_601149
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
  var valid_601150 = header.getOrDefault("X-Amz-Date")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Date", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Security-Token")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Security-Token", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Content-Sha256", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Algorithm")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Algorithm", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Signature")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Signature", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-SignedHeaders", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Credential")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Credential", valid_601156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601158: Call_DeleteTags_601146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ## 
  let valid = call_601158.validator(path, query, header, formData, body)
  let scheme = call_601158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601158.url(scheme.get, call_601158.host, call_601158.base,
                         call_601158.route, valid.getOrDefault("path"))
  result = hook(call_601158, url, valid)

proc call*(call_601159: Call_DeleteTags_601146; FileSystemId: string; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from a file system. If the <code>DeleteTags</code> request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DeleteTags</code> action.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tags you want to delete (String).
  ##   body: JObject (required)
  var path_601160 = newJObject()
  var body_601161 = newJObject()
  add(path_601160, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_601161 = body
  result = call_601159.call(path_601160, nil, nil, nil, body_601161)

var deleteTags* = Call_DeleteTags_601146(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticfilesystem.amazonaws.com", route: "/2015-02-01/delete-tags/{FileSystemId}",
                                      validator: validate_DeleteTags_601147,
                                      base: "/", url: url_DeleteTags_601148,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleConfiguration_601176 = ref object of OpenApiRestCall_600426
proc url_PutLifecycleConfiguration_601178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/lifecycle-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_PutLifecycleConfiguration_601177(path: JsonNode; query: JsonNode;
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
  var valid_601179 = path.getOrDefault("FileSystemId")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "FileSystemId", valid_601179
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
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601188: Call_PutLifecycleConfiguration_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ## 
  let valid = call_601188.validator(path, query, header, formData, body)
  let scheme = call_601188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601188.url(scheme.get, call_601188.host, call_601188.base,
                         call_601188.route, valid.getOrDefault("path"))
  result = hook(call_601188, url, valid)

proc call*(call_601189: Call_PutLifecycleConfiguration_601176;
          FileSystemId: string; body: JsonNode): Recallable =
  ## putLifecycleConfiguration
  ## <p>Enables lifecycle management by creating a new <code>LifecycleConfiguration</code> object. A <code>LifecycleConfiguration</code> object defines when files in an Amazon EFS file system are automatically transitioned to the lower-cost EFS Infrequent Access (IA) storage class. A <code>LifecycleConfiguration</code> applies to all files in a file system.</p> <p>Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a <code>LifecycleConfiguration</code> object already exists for the specified file system, a <code>PutLifecycleConfiguration</code> call modifies the existing configuration. A <code>PutLifecycleConfiguration</code> call with an empty <code>LifecyclePolicies</code> array in the request body deletes any existing <code>LifecycleConfiguration</code> and disables lifecycle management.</p> <p>In the request, specify the following: </p> <ul> <li> <p>The ID for the file system for which you are enabling, disabling, or modifying lifecycle management.</p> </li> <li> <p>A <code>LifecyclePolicies</code> array of <code>LifecyclePolicy</code> objects that define when files are moved to the IA storage class. The array can contain only one <code>LifecyclePolicy</code> item.</p> </li> </ul> <p>This operation requires permissions for the <code>elasticfilesystem:PutLifecycleConfiguration</code> operation.</p> <p>To apply a <code>LifecycleConfiguration</code> object to an encrypted file system, you need the same AWS Key Management Service (AWS KMS) permissions as when you created the encrypted file system. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system for which you are creating the <code>LifecycleConfiguration</code> object (String).
  ##   body: JObject (required)
  var path_601190 = newJObject()
  var body_601191 = newJObject()
  add(path_601190, "FileSystemId", newJString(FileSystemId))
  if body != nil:
    body_601191 = body
  result = call_601189.call(path_601190, nil, nil, nil, body_601191)

var putLifecycleConfiguration* = Call_PutLifecycleConfiguration_601176(
    name: "putLifecycleConfiguration", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_PutLifecycleConfiguration_601177, base: "/",
    url: url_PutLifecycleConfiguration_601178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLifecycleConfiguration_601162 = ref object of OpenApiRestCall_600426
proc url_DescribeLifecycleConfiguration_601164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/file-systems/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/lifecycle-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeLifecycleConfiguration_601163(path: JsonNode;
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
  var valid_601165 = path.getOrDefault("FileSystemId")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "FileSystemId", valid_601165
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_DescribeLifecycleConfiguration_601162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"))
  result = hook(call_601173, url, valid)

proc call*(call_601174: Call_DescribeLifecycleConfiguration_601162;
          FileSystemId: string): Recallable =
  ## describeLifecycleConfiguration
  ## <p>Returns the current <code>LifecycleConfiguration</code> object for the specified Amazon EFS file system. EFS lifecycle management uses the <code>LifecycleConfiguration</code> object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a <code>LifecycleConfiguration</code> object, the call returns an empty array in the response.</p> <p>This operation requires permissions for the <code>elasticfilesystem:DescribeLifecycleConfiguration</code> operation.</p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose <code>LifecycleConfiguration</code> object you want to retrieve (String).
  var path_601175 = newJObject()
  add(path_601175, "FileSystemId", newJString(FileSystemId))
  result = call_601174.call(path_601175, nil, nil, nil, nil)

var describeLifecycleConfiguration* = Call_DescribeLifecycleConfiguration_601162(
    name: "describeLifecycleConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration",
    validator: validate_DescribeLifecycleConfiguration_601163, base: "/",
    url: url_DescribeLifecycleConfiguration_601164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyMountTargetSecurityGroups_601206 = ref object of OpenApiRestCall_600426
proc url_ModifyMountTargetSecurityGroups_601208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "MountTargetId" in path, "`MountTargetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/mount-targets/"),
               (kind: VariableSegment, value: "MountTargetId"),
               (kind: ConstantSegment, value: "/security-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ModifyMountTargetSecurityGroups_601207(path: JsonNode;
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
  var valid_601209 = path.getOrDefault("MountTargetId")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "MountTargetId", valid_601209
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
  var valid_601210 = header.getOrDefault("X-Amz-Date")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Date", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Security-Token")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Security-Token", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Content-Sha256", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Algorithm")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Algorithm", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Signature")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Signature", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-SignedHeaders", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Credential")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Credential", valid_601216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601218: Call_ModifyMountTargetSecurityGroups_601206;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_601218.validator(path, query, header, formData, body)
  let scheme = call_601218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601218.url(scheme.get, call_601218.host, call_601218.base,
                         call_601218.route, valid.getOrDefault("path"))
  result = hook(call_601218, url, valid)

proc call*(call_601219: Call_ModifyMountTargetSecurityGroups_601206;
          MountTargetId: string; body: JsonNode): Recallable =
  ## modifyMountTargetSecurityGroups
  ## <p>Modifies the set of security groups in effect for a mount target.</p> <p>When you create a mount target, Amazon EFS also creates a new network interface. For more information, see <a>CreateMountTarget</a>. This operation replaces the security groups in effect for the network interface associated with a mount target, with the <code>SecurityGroups</code> provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>. </p> <p>The operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:ModifyMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:ModifyNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to modify.
  ##   body: JObject (required)
  var path_601220 = newJObject()
  var body_601221 = newJObject()
  add(path_601220, "MountTargetId", newJString(MountTargetId))
  if body != nil:
    body_601221 = body
  result = call_601219.call(path_601220, nil, nil, nil, body_601221)

var modifyMountTargetSecurityGroups* = Call_ModifyMountTargetSecurityGroups_601206(
    name: "modifyMountTargetSecurityGroups", meth: HttpMethod.HttpPut,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_ModifyMountTargetSecurityGroups_601207, base: "/",
    url: url_ModifyMountTargetSecurityGroups_601208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMountTargetSecurityGroups_601192 = ref object of OpenApiRestCall_600426
proc url_DescribeMountTargetSecurityGroups_601194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "MountTargetId" in path, "`MountTargetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/mount-targets/"),
               (kind: VariableSegment, value: "MountTargetId"),
               (kind: ConstantSegment, value: "/security-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeMountTargetSecurityGroups_601193(path: JsonNode;
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
  var valid_601195 = path.getOrDefault("MountTargetId")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = nil)
  if valid_601195 != nil:
    section.add "MountTargetId", valid_601195
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
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Content-Sha256", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Algorithm")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Algorithm", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Signature")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Signature", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-SignedHeaders", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Credential")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Credential", valid_601202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601203: Call_DescribeMountTargetSecurityGroups_601192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ## 
  let valid = call_601203.validator(path, query, header, formData, body)
  let scheme = call_601203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601203.url(scheme.get, call_601203.host, call_601203.base,
                         call_601203.route, valid.getOrDefault("path"))
  result = hook(call_601203, url, valid)

proc call*(call_601204: Call_DescribeMountTargetSecurityGroups_601192;
          MountTargetId: string): Recallable =
  ## describeMountTargetSecurityGroups
  ## <p>Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not <code>deleted</code>.</p> <p>This operation requires permissions for the following actions:</p> <ul> <li> <p> <code>elasticfilesystem:DescribeMountTargetSecurityGroups</code> action on the mount target's file system. </p> </li> <li> <p> <code>ec2:DescribeNetworkInterfaceAttribute</code> action on the mount target's network interface. </p> </li> </ul>
  ##   MountTargetId: string (required)
  ##                : The ID of the mount target whose security groups you want to retrieve.
  var path_601205 = newJObject()
  add(path_601205, "MountTargetId", newJString(MountTargetId))
  result = call_601204.call(path_601205, nil, nil, nil, nil)

var describeMountTargetSecurityGroups* = Call_DescribeMountTargetSecurityGroups_601192(
    name: "describeMountTargetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/mount-targets/{MountTargetId}/security-groups",
    validator: validate_DescribeMountTargetSecurityGroups_601193, base: "/",
    url: url_DescribeMountTargetSecurityGroups_601194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_601222 = ref object of OpenApiRestCall_600426
proc url_DescribeTags_601224(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FileSystemId" in path, "`FileSystemId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-02-01/tags/"),
               (kind: VariableSegment, value: "FileSystemId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeTags_601223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601225 = path.getOrDefault("FileSystemId")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "FileSystemId", valid_601225
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: JInt
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  section = newJObject()
  var valid_601226 = query.getOrDefault("Marker")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "Marker", valid_601226
  var valid_601227 = query.getOrDefault("MaxItems")
  valid_601227 = validateParameter(valid_601227, JInt, required = false, default = nil)
  if valid_601227 != nil:
    section.add "MaxItems", valid_601227
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
  var valid_601228 = header.getOrDefault("X-Amz-Date")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Date", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Security-Token")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Security-Token", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_DescribeTags_601222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_DescribeTags_601222; FileSystemId: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## describeTags
  ## <p>Returns the tags associated with a file system. The order of tags returned in the response of one <code>DescribeTags</code> call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. </p> <p> This operation requires permissions for the <code>elasticfilesystem:DescribeTags</code> action. </p>
  ##   FileSystemId: string (required)
  ##               : The ID of the file system whose tag set you want to retrieve.
  ##   Marker: string
  ##         : (Optional) An opaque pagination token returned from a previous <code>DescribeTags</code> operation (String). If present, it specifies to continue the list from where the previous call left off.
  ##   MaxItems: int
  ##           : (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 10 per page if you have more than 10 tags.
  var path_601237 = newJObject()
  var query_601238 = newJObject()
  add(path_601237, "FileSystemId", newJString(FileSystemId))
  add(query_601238, "Marker", newJString(Marker))
  add(query_601238, "MaxItems", newJInt(MaxItems))
  result = call_601236.call(path_601237, query_601238, nil, nil, nil)

var describeTags* = Call_DescribeTags_601222(name: "describeTags",
    meth: HttpMethod.HttpGet, host: "elasticfilesystem.amazonaws.com",
    route: "/2015-02-01/tags/{FileSystemId}/", validator: validate_DescribeTags_601223,
    base: "/", url: url_DescribeTags_601224, schemes: {Scheme.Https, Scheme.Http})
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
