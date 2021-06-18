
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Migration Hub
## version: 2017-05-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The AWS Migration Hub API methods help to obtain server and application migration status and integrate your resource-specific migration tool by providing a programmatic interface to Migration Hub.</p> <p>Remember that you must set your AWS Migration Hub home region before you call any of these APIs, or a <code>HomeRegionNotSetException</code> error will be returned. Also, you must make the API calls while in your home region.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mgh/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "mgh.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mgh.ap-southeast-1.amazonaws.com",
                               "us-west-2": "mgh.us-west-2.amazonaws.com",
                               "eu-west-2": "mgh.eu-west-2.amazonaws.com", "ap-northeast-3": "mgh.ap-northeast-3.amazonaws.com", "eu-central-1": "mgh.eu-central-1.amazonaws.com",
                               "us-east-2": "mgh.us-east-2.amazonaws.com",
                               "us-east-1": "mgh.us-east-1.amazonaws.com", "cn-northwest-1": "mgh.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "mgh.ap-south-1.amazonaws.com",
                               "eu-north-1": "mgh.eu-north-1.amazonaws.com", "ap-northeast-2": "mgh.ap-northeast-2.amazonaws.com",
                               "us-west-1": "mgh.us-west-1.amazonaws.com", "us-gov-east-1": "mgh.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "mgh.eu-west-3.amazonaws.com",
                               "cn-north-1": "mgh.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "mgh.sa-east-1.amazonaws.com",
                               "eu-west-1": "mgh.eu-west-1.amazonaws.com", "us-gov-west-1": "mgh.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mgh.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "mgh.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "mgh.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mgh.ap-southeast-1.amazonaws.com",
      "us-west-2": "mgh.us-west-2.amazonaws.com",
      "eu-west-2": "mgh.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mgh.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mgh.eu-central-1.amazonaws.com",
      "us-east-2": "mgh.us-east-2.amazonaws.com",
      "us-east-1": "mgh.us-east-1.amazonaws.com",
      "cn-northwest-1": "mgh.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mgh.ap-south-1.amazonaws.com",
      "eu-north-1": "mgh.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mgh.ap-northeast-2.amazonaws.com",
      "us-west-1": "mgh.us-west-1.amazonaws.com",
      "us-gov-east-1": "mgh.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mgh.eu-west-3.amazonaws.com",
      "cn-north-1": "mgh.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mgh.sa-east-1.amazonaws.com",
      "eu-west-1": "mgh.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mgh.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mgh.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mgh.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "AWSMigrationHub"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateCreatedArtifact_402656288 = ref object of OpenApiRestCall_402656038
proc url_AssociateCreatedArtifact_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateCreatedArtifact_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Associates a created artifact of an AWS cloud resource, the target receiving the migration, with the migration task performed by a migration tool. This API has the following traits:</p> <ul> <li> <p>Migration tools can call the <code>AssociateCreatedArtifact</code> operation to indicate which AWS artifact is associated with a migration task.</p> </li> <li> <p>The created artifact name must be provided in ARN (Amazon Resource Name) format which will contain information about type and region; for example: <code>arn:aws:ec2:us-east-1:488216288981:image/ami-6d0ba87b</code>.</p> </li> <li> <p>Examples of the AWS resource behind the created artifact are, AMI's, EC2 instance, or DMS endpoint, etc.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656384 = header.getOrDefault("X-Amz-Target")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true, default = newJString(
      "AWSMigrationHub.AssociateCreatedArtifact"))
  if valid_402656384 != nil:
    section.add "X-Amz-Target", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Security-Token", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Signature")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Signature", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Algorithm", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Date")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Date", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Credential")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Credential", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656391
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

proc call*(call_402656406: Call_AssociateCreatedArtifact_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates a created artifact of an AWS cloud resource, the target receiving the migration, with the migration task performed by a migration tool. This API has the following traits:</p> <ul> <li> <p>Migration tools can call the <code>AssociateCreatedArtifact</code> operation to indicate which AWS artifact is associated with a migration task.</p> </li> <li> <p>The created artifact name must be provided in ARN (Amazon Resource Name) format which will contain information about type and region; for example: <code>arn:aws:ec2:us-east-1:488216288981:image/ami-6d0ba87b</code>.</p> </li> <li> <p>Examples of the AWS resource behind the created artifact are, AMI's, EC2 instance, or DMS endpoint, etc.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656406.validator(path, query, header, formData, body, _)
  let scheme = call_402656406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656406.makeUrl(scheme.get, call_402656406.host, call_402656406.base,
                                   call_402656406.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656406, uri, valid, _)

proc call*(call_402656455: Call_AssociateCreatedArtifact_402656288;
           body: JsonNode): Recallable =
  ## associateCreatedArtifact
  ## <p>Associates a created artifact of an AWS cloud resource, the target receiving the migration, with the migration task performed by a migration tool. This API has the following traits:</p> <ul> <li> <p>Migration tools can call the <code>AssociateCreatedArtifact</code> operation to indicate which AWS artifact is associated with a migration task.</p> </li> <li> <p>The created artifact name must be provided in ARN (Amazon Resource Name) format which will contain information about type and region; for example: <code>arn:aws:ec2:us-east-1:488216288981:image/ami-6d0ba87b</code>.</p> </li> <li> <p>Examples of the AWS resource behind the created artifact are, AMI's, EC2 instance, or DMS endpoint, etc.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656456 = newJObject()
  if body != nil:
    body_402656456 = body
  result = call_402656455.call(nil, nil, nil, nil, body_402656456)

var associateCreatedArtifact* = Call_AssociateCreatedArtifact_402656288(
    name: "associateCreatedArtifact", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.AssociateCreatedArtifact",
    validator: validate_AssociateCreatedArtifact_402656289, base: "/",
    makeUrl: url_AssociateCreatedArtifact_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateDiscoveredResource_402656483 = ref object of OpenApiRestCall_402656038
proc url_AssociateDiscoveredResource_402656485(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDiscoveredResource_402656484(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates a discovered resource ID from Application Discovery Service with a migration task.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656486 = header.getOrDefault("X-Amz-Target")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true, default = newJString(
      "AWSMigrationHub.AssociateDiscoveredResource"))
  if valid_402656486 != nil:
    section.add "X-Amz-Target", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
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

proc call*(call_402656495: Call_AssociateDiscoveredResource_402656483;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a discovered resource ID from Application Discovery Service with a migration task.
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_AssociateDiscoveredResource_402656483;
           body: JsonNode): Recallable =
  ## associateDiscoveredResource
  ## Associates a discovered resource ID from Application Discovery Service with a migration task.
  ##   
                                                                                                  ## body: JObject (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var associateDiscoveredResource* = Call_AssociateDiscoveredResource_402656483(
    name: "associateDiscoveredResource", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.AssociateDiscoveredResource",
    validator: validate_AssociateDiscoveredResource_402656484, base: "/",
    makeUrl: url_AssociateDiscoveredResource_402656485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProgressUpdateStream_402656498 = ref object of OpenApiRestCall_402656038
proc url_CreateProgressUpdateStream_402656500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProgressUpdateStream_402656499(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a progress update stream which is an AWS resource used for access control as well as a namespace for migration task names that is implicitly linked to your AWS account. It must uniquely identify the migration tool as it is used for all updates made by the tool; however, it does not need to be unique for each AWS account because it is scoped to the AWS account.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Target")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true, default = newJString(
      "AWSMigrationHub.CreateProgressUpdateStream"))
  if valid_402656501 != nil:
    section.add "X-Amz-Target", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
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

proc call*(call_402656510: Call_CreateProgressUpdateStream_402656498;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a progress update stream which is an AWS resource used for access control as well as a namespace for migration task names that is implicitly linked to your AWS account. It must uniquely identify the migration tool as it is used for all updates made by the tool; however, it does not need to be unique for each AWS account because it is scoped to the AWS account.
                                                                                         ## 
  let valid = call_402656510.validator(path, query, header, formData, body, _)
  let scheme = call_402656510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656510.makeUrl(scheme.get, call_402656510.host, call_402656510.base,
                                   call_402656510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656510, uri, valid, _)

proc call*(call_402656511: Call_CreateProgressUpdateStream_402656498;
           body: JsonNode): Recallable =
  ## createProgressUpdateStream
  ## Creates a progress update stream which is an AWS resource used for access control as well as a namespace for migration task names that is implicitly linked to your AWS account. It must uniquely identify the migration tool as it is used for all updates made by the tool; however, it does not need to be unique for each AWS account because it is scoped to the AWS account.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656512 = newJObject()
  if body != nil:
    body_402656512 = body
  result = call_402656511.call(nil, nil, nil, nil, body_402656512)

var createProgressUpdateStream* = Call_CreateProgressUpdateStream_402656498(
    name: "createProgressUpdateStream", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.CreateProgressUpdateStream",
    validator: validate_CreateProgressUpdateStream_402656499, base: "/",
    makeUrl: url_CreateProgressUpdateStream_402656500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProgressUpdateStream_402656513 = ref object of OpenApiRestCall_402656038
proc url_DeleteProgressUpdateStream_402656515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProgressUpdateStream_402656514(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes a progress update stream, including all of its tasks, which was previously created as an AWS resource used for access control. This API has the following traits:</p> <ul> <li> <p>The only parameter needed for <code>DeleteProgressUpdateStream</code> is the stream name (same as a <code>CreateProgressUpdateStream</code> call).</p> </li> <li> <p>The call will return, and a background process will asynchronously delete the stream and all of its resources (tasks, associated resources, resource attributes, created artifacts).</p> </li> <li> <p>If the stream takes time to be deleted, it might still show up on a <code>ListProgressUpdateStreams</code> call.</p> </li> <li> <p> <code>CreateProgressUpdateStream</code>, <code>ImportMigrationTask</code>, <code>NotifyMigrationTaskState</code>, and all Associate[*] APIs related to the tasks belonging to the stream will throw "InvalidInputException" if the stream of the same name is in the process of being deleted.</p> </li> <li> <p>Once the stream and all of its resources are deleted, <code>CreateProgressUpdateStream</code> for a stream of the same name will succeed, and that stream will be an entirely new logical resource (without any resources associated with the old stream).</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656516 = header.getOrDefault("X-Amz-Target")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true, default = newJString(
      "AWSMigrationHub.DeleteProgressUpdateStream"))
  if valid_402656516 != nil:
    section.add "X-Amz-Target", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Security-Token", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Signature")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Signature", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Algorithm", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Date")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Date", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Credential")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Credential", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656523
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

proc call*(call_402656525: Call_DeleteProgressUpdateStream_402656513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a progress update stream, including all of its tasks, which was previously created as an AWS resource used for access control. This API has the following traits:</p> <ul> <li> <p>The only parameter needed for <code>DeleteProgressUpdateStream</code> is the stream name (same as a <code>CreateProgressUpdateStream</code> call).</p> </li> <li> <p>The call will return, and a background process will asynchronously delete the stream and all of its resources (tasks, associated resources, resource attributes, created artifacts).</p> </li> <li> <p>If the stream takes time to be deleted, it might still show up on a <code>ListProgressUpdateStreams</code> call.</p> </li> <li> <p> <code>CreateProgressUpdateStream</code>, <code>ImportMigrationTask</code>, <code>NotifyMigrationTaskState</code>, and all Associate[*] APIs related to the tasks belonging to the stream will throw "InvalidInputException" if the stream of the same name is in the process of being deleted.</p> </li> <li> <p>Once the stream and all of its resources are deleted, <code>CreateProgressUpdateStream</code> for a stream of the same name will succeed, and that stream will be an entirely new logical resource (without any resources associated with the old stream).</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_DeleteProgressUpdateStream_402656513;
           body: JsonNode): Recallable =
  ## deleteProgressUpdateStream
  ## <p>Deletes a progress update stream, including all of its tasks, which was previously created as an AWS resource used for access control. This API has the following traits:</p> <ul> <li> <p>The only parameter needed for <code>DeleteProgressUpdateStream</code> is the stream name (same as a <code>CreateProgressUpdateStream</code> call).</p> </li> <li> <p>The call will return, and a background process will asynchronously delete the stream and all of its resources (tasks, associated resources, resource attributes, created artifacts).</p> </li> <li> <p>If the stream takes time to be deleted, it might still show up on a <code>ListProgressUpdateStreams</code> call.</p> </li> <li> <p> <code>CreateProgressUpdateStream</code>, <code>ImportMigrationTask</code>, <code>NotifyMigrationTaskState</code>, and all Associate[*] APIs related to the tasks belonging to the stream will throw "InvalidInputException" if the stream of the same name is in the process of being deleted.</p> </li> <li> <p>Once the stream and all of its resources are deleted, <code>CreateProgressUpdateStream</code> for a stream of the same name will succeed, and that stream will be an entirely new logical resource (without any resources associated with the old stream).</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656527 = newJObject()
  if body != nil:
    body_402656527 = body
  result = call_402656526.call(nil, nil, nil, nil, body_402656527)

var deleteProgressUpdateStream* = Call_DeleteProgressUpdateStream_402656513(
    name: "deleteProgressUpdateStream", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.DeleteProgressUpdateStream",
    validator: validate_DeleteProgressUpdateStream_402656514, base: "/",
    makeUrl: url_DeleteProgressUpdateStream_402656515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApplicationState_402656528 = ref object of OpenApiRestCall_402656038
proc url_DescribeApplicationState_402656530(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApplicationState_402656529(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the migration status of an application.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656531 = header.getOrDefault("X-Amz-Target")
  valid_402656531 = validateParameter(valid_402656531, JString, required = true, default = newJString(
      "AWSMigrationHub.DescribeApplicationState"))
  if valid_402656531 != nil:
    section.add "X-Amz-Target", valid_402656531
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656540: Call_DescribeApplicationState_402656528;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the migration status of an application.
                                                                                         ## 
  let valid = call_402656540.validator(path, query, header, formData, body, _)
  let scheme = call_402656540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656540.makeUrl(scheme.get, call_402656540.host, call_402656540.base,
                                   call_402656540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656540, uri, valid, _)

proc call*(call_402656541: Call_DescribeApplicationState_402656528;
           body: JsonNode): Recallable =
  ## describeApplicationState
  ## Gets the migration status of an application.
  ##   body: JObject (required)
  var body_402656542 = newJObject()
  if body != nil:
    body_402656542 = body
  result = call_402656541.call(nil, nil, nil, nil, body_402656542)

var describeApplicationState* = Call_DescribeApplicationState_402656528(
    name: "describeApplicationState", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.DescribeApplicationState",
    validator: validate_DescribeApplicationState_402656529, base: "/",
    makeUrl: url_DescribeApplicationState_402656530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMigrationTask_402656543 = ref object of OpenApiRestCall_402656038
proc url_DescribeMigrationTask_402656545(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMigrationTask_402656544(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of all attributes associated with a specific migration task.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656546 = header.getOrDefault("X-Amz-Target")
  valid_402656546 = validateParameter(valid_402656546, JString, required = true, default = newJString(
      "AWSMigrationHub.DescribeMigrationTask"))
  if valid_402656546 != nil:
    section.add "X-Amz-Target", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Security-Token", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Signature")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Signature", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Algorithm", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Date")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Date", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Credential")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Credential", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656553
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

proc call*(call_402656555: Call_DescribeMigrationTask_402656543;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of all attributes associated with a specific migration task.
                                                                                         ## 
  let valid = call_402656555.validator(path, query, header, formData, body, _)
  let scheme = call_402656555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656555.makeUrl(scheme.get, call_402656555.host, call_402656555.base,
                                   call_402656555.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656555, uri, valid, _)

proc call*(call_402656556: Call_DescribeMigrationTask_402656543; body: JsonNode): Recallable =
  ## describeMigrationTask
  ## Retrieves a list of all attributes associated with a specific migration task.
  ##   
                                                                                  ## body: JObject (required)
  var body_402656557 = newJObject()
  if body != nil:
    body_402656557 = body
  result = call_402656556.call(nil, nil, nil, nil, body_402656557)

var describeMigrationTask* = Call_DescribeMigrationTask_402656543(
    name: "describeMigrationTask", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.DescribeMigrationTask",
    validator: validate_DescribeMigrationTask_402656544, base: "/",
    makeUrl: url_DescribeMigrationTask_402656545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCreatedArtifact_402656558 = ref object of OpenApiRestCall_402656038
proc url_DisassociateCreatedArtifact_402656560(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateCreatedArtifact_402656559(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Disassociates a created artifact of an AWS resource with a migration task performed by a migration tool that was previously associated. This API has the following traits:</p> <ul> <li> <p>A migration user can call the <code>DisassociateCreatedArtifacts</code> operation to disassociate a created AWS Artifact from a migration task.</p> </li> <li> <p>The created artifact name must be provided in ARN (Amazon Resource Name) format which will contain information about type and region; for example: <code>arn:aws:ec2:us-east-1:488216288981:image/ami-6d0ba87b</code>.</p> </li> <li> <p>Examples of the AWS resource behind the created artifact are, AMI's, EC2 instance, or RDS instance, etc.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656561 = header.getOrDefault("X-Amz-Target")
  valid_402656561 = validateParameter(valid_402656561, JString, required = true, default = newJString(
      "AWSMigrationHub.DisassociateCreatedArtifact"))
  if valid_402656561 != nil:
    section.add "X-Amz-Target", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Security-Token", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Signature")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Signature", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Algorithm", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Date")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Date", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Credential")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Credential", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656568
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

proc call*(call_402656570: Call_DisassociateCreatedArtifact_402656558;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates a created artifact of an AWS resource with a migration task performed by a migration tool that was previously associated. This API has the following traits:</p> <ul> <li> <p>A migration user can call the <code>DisassociateCreatedArtifacts</code> operation to disassociate a created AWS Artifact from a migration task.</p> </li> <li> <p>The created artifact name must be provided in ARN (Amazon Resource Name) format which will contain information about type and region; for example: <code>arn:aws:ec2:us-east-1:488216288981:image/ami-6d0ba87b</code>.</p> </li> <li> <p>Examples of the AWS resource behind the created artifact are, AMI's, EC2 instance, or RDS instance, etc.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656570.validator(path, query, header, formData, body, _)
  let scheme = call_402656570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656570.makeUrl(scheme.get, call_402656570.host, call_402656570.base,
                                   call_402656570.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656570, uri, valid, _)

proc call*(call_402656571: Call_DisassociateCreatedArtifact_402656558;
           body: JsonNode): Recallable =
  ## disassociateCreatedArtifact
  ## <p>Disassociates a created artifact of an AWS resource with a migration task performed by a migration tool that was previously associated. This API has the following traits:</p> <ul> <li> <p>A migration user can call the <code>DisassociateCreatedArtifacts</code> operation to disassociate a created AWS Artifact from a migration task.</p> </li> <li> <p>The created artifact name must be provided in ARN (Amazon Resource Name) format which will contain information about type and region; for example: <code>arn:aws:ec2:us-east-1:488216288981:image/ami-6d0ba87b</code>.</p> </li> <li> <p>Examples of the AWS resource behind the created artifact are, AMI's, EC2 instance, or RDS instance, etc.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656572 = newJObject()
  if body != nil:
    body_402656572 = body
  result = call_402656571.call(nil, nil, nil, nil, body_402656572)

var disassociateCreatedArtifact* = Call_DisassociateCreatedArtifact_402656558(
    name: "disassociateCreatedArtifact", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.DisassociateCreatedArtifact",
    validator: validate_DisassociateCreatedArtifact_402656559, base: "/",
    makeUrl: url_DisassociateCreatedArtifact_402656560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDiscoveredResource_402656573 = ref object of OpenApiRestCall_402656038
proc url_DisassociateDiscoveredResource_402656575(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateDiscoveredResource_402656574(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociate an Application Discovery Service discovered resource from a migration task.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656576 = header.getOrDefault("X-Amz-Target")
  valid_402656576 = validateParameter(valid_402656576, JString, required = true, default = newJString(
      "AWSMigrationHub.DisassociateDiscoveredResource"))
  if valid_402656576 != nil:
    section.add "X-Amz-Target", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
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

proc call*(call_402656585: Call_DisassociateDiscoveredResource_402656573;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociate an Application Discovery Service discovered resource from a migration task.
                                                                                         ## 
  let valid = call_402656585.validator(path, query, header, formData, body, _)
  let scheme = call_402656585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656585.makeUrl(scheme.get, call_402656585.host, call_402656585.base,
                                   call_402656585.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656585, uri, valid, _)

proc call*(call_402656586: Call_DisassociateDiscoveredResource_402656573;
           body: JsonNode): Recallable =
  ## disassociateDiscoveredResource
  ## Disassociate an Application Discovery Service discovered resource from a migration task.
  ##   
                                                                                             ## body: JObject (required)
  var body_402656587 = newJObject()
  if body != nil:
    body_402656587 = body
  result = call_402656586.call(nil, nil, nil, nil, body_402656587)

var disassociateDiscoveredResource* = Call_DisassociateDiscoveredResource_402656573(
    name: "disassociateDiscoveredResource", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.DisassociateDiscoveredResource",
    validator: validate_DisassociateDiscoveredResource_402656574, base: "/",
    makeUrl: url_DisassociateDiscoveredResource_402656575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportMigrationTask_402656588 = ref object of OpenApiRestCall_402656038
proc url_ImportMigrationTask_402656590(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportMigrationTask_402656589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Registers a new migration task which represents a server, database, etc., being migrated to AWS by a migration tool.</p> <p>This API is a prerequisite to calling the <code>NotifyMigrationTaskState</code> API as the migration tool must first register the migration task with Migration Hub.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Target")
  valid_402656591 = validateParameter(valid_402656591, JString, required = true, default = newJString(
      "AWSMigrationHub.ImportMigrationTask"))
  if valid_402656591 != nil:
    section.add "X-Amz-Target", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Security-Token", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Signature")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Signature", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Algorithm", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Date")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Date", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Credential")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Credential", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656598
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

proc call*(call_402656600: Call_ImportMigrationTask_402656588;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers a new migration task which represents a server, database, etc., being migrated to AWS by a migration tool.</p> <p>This API is a prerequisite to calling the <code>NotifyMigrationTaskState</code> API as the migration tool must first register the migration task with Migration Hub.</p>
                                                                                         ## 
  let valid = call_402656600.validator(path, query, header, formData, body, _)
  let scheme = call_402656600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656600.makeUrl(scheme.get, call_402656600.host, call_402656600.base,
                                   call_402656600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656600, uri, valid, _)

proc call*(call_402656601: Call_ImportMigrationTask_402656588; body: JsonNode): Recallable =
  ## importMigrationTask
  ## <p>Registers a new migration task which represents a server, database, etc., being migrated to AWS by a migration tool.</p> <p>This API is a prerequisite to calling the <code>NotifyMigrationTaskState</code> API as the migration tool must first register the migration task with Migration Hub.</p>
  ##   
                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656602 = newJObject()
  if body != nil:
    body_402656602 = body
  result = call_402656601.call(nil, nil, nil, nil, body_402656602)

var importMigrationTask* = Call_ImportMigrationTask_402656588(
    name: "importMigrationTask", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.ImportMigrationTask",
    validator: validate_ImportMigrationTask_402656589, base: "/",
    makeUrl: url_ImportMigrationTask_402656590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationStates_402656603 = ref object of OpenApiRestCall_402656038
proc url_ListApplicationStates_402656605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplicationStates_402656604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all the migration statuses for your applications. If you use the optional <code>ApplicationIds</code> parameter, only the migration statuses for those applications will be returned.
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
  var valid_402656606 = query.getOrDefault("MaxResults")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "MaxResults", valid_402656606
  var valid_402656607 = query.getOrDefault("NextToken")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "NextToken", valid_402656607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656608 = header.getOrDefault("X-Amz-Target")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true, default = newJString(
      "AWSMigrationHub.ListApplicationStates"))
  if valid_402656608 != nil:
    section.add "X-Amz-Target", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Security-Token", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Signature")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Signature", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Algorithm", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Date")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Date", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Credential")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Credential", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656615
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

proc call*(call_402656617: Call_ListApplicationStates_402656603;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the migration statuses for your applications. If you use the optional <code>ApplicationIds</code> parameter, only the migration statuses for those applications will be returned.
                                                                                         ## 
  let valid = call_402656617.validator(path, query, header, formData, body, _)
  let scheme = call_402656617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656617.makeUrl(scheme.get, call_402656617.host, call_402656617.base,
                                   call_402656617.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656617, uri, valid, _)

proc call*(call_402656618: Call_ListApplicationStates_402656603; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApplicationStates
  ## Lists all the migration statuses for your applications. If you use the optional <code>ApplicationIds</code> parameter, only the migration statuses for those applications will be returned.
  ##   
                                                                                                                                                                                                ## MaxResults: string
                                                                                                                                                                                                ##             
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                        ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                   ## token
  var query_402656619 = newJObject()
  var body_402656620 = newJObject()
  add(query_402656619, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656620 = body
  add(query_402656619, "NextToken", newJString(NextToken))
  result = call_402656618.call(nil, query_402656619, nil, nil, body_402656620)

var listApplicationStates* = Call_ListApplicationStates_402656603(
    name: "listApplicationStates", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.ListApplicationStates",
    validator: validate_ListApplicationStates_402656604, base: "/",
    makeUrl: url_ListApplicationStates_402656605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCreatedArtifacts_402656621 = ref object of OpenApiRestCall_402656038
proc url_ListCreatedArtifacts_402656623(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCreatedArtifacts_402656622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the created artifacts attached to a given migration task in an update stream. This API has the following traits:</p> <ul> <li> <p>Gets the list of the created artifacts while migration is taking place.</p> </li> <li> <p>Shows the artifacts created by the migration tool that was associated by the <code>AssociateCreatedArtifact</code> API. </p> </li> <li> <p>Lists created artifacts in a paginated interface. </p> </li> </ul>
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
  var valid_402656624 = query.getOrDefault("MaxResults")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "MaxResults", valid_402656624
  var valid_402656625 = query.getOrDefault("NextToken")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "NextToken", valid_402656625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656626 = header.getOrDefault("X-Amz-Target")
  valid_402656626 = validateParameter(valid_402656626, JString, required = true, default = newJString(
      "AWSMigrationHub.ListCreatedArtifacts"))
  if valid_402656626 != nil:
    section.add "X-Amz-Target", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Security-Token", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Signature")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Signature", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Algorithm", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Date")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Date", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Credential")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Credential", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656633
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

proc call*(call_402656635: Call_ListCreatedArtifacts_402656621;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the created artifacts attached to a given migration task in an update stream. This API has the following traits:</p> <ul> <li> <p>Gets the list of the created artifacts while migration is taking place.</p> </li> <li> <p>Shows the artifacts created by the migration tool that was associated by the <code>AssociateCreatedArtifact</code> API. </p> </li> <li> <p>Lists created artifacts in a paginated interface. </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656635.validator(path, query, header, formData, body, _)
  let scheme = call_402656635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656635.makeUrl(scheme.get, call_402656635.host, call_402656635.base,
                                   call_402656635.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656635, uri, valid, _)

proc call*(call_402656636: Call_ListCreatedArtifacts_402656621; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCreatedArtifacts
  ## <p>Lists the created artifacts attached to a given migration task in an update stream. This API has the following traits:</p> <ul> <li> <p>Gets the list of the created artifacts while migration is taking place.</p> </li> <li> <p>Shows the artifacts created by the migration tool that was associated by the <code>AssociateCreatedArtifact</code> API. </p> </li> <li> <p>Lists created artifacts in a paginated interface. </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## token
  var query_402656637 = newJObject()
  var body_402656638 = newJObject()
  add(query_402656637, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656638 = body
  add(query_402656637, "NextToken", newJString(NextToken))
  result = call_402656636.call(nil, query_402656637, nil, nil, body_402656638)

var listCreatedArtifacts* = Call_ListCreatedArtifacts_402656621(
    name: "listCreatedArtifacts", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.ListCreatedArtifacts",
    validator: validate_ListCreatedArtifacts_402656622, base: "/",
    makeUrl: url_ListCreatedArtifacts_402656623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoveredResources_402656639 = ref object of OpenApiRestCall_402656038
proc url_ListDiscoveredResources_402656641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDiscoveredResources_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists discovered resources associated with the given <code>MigrationTask</code>.
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
  var valid_402656642 = query.getOrDefault("MaxResults")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "MaxResults", valid_402656642
  var valid_402656643 = query.getOrDefault("NextToken")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "NextToken", valid_402656643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656644 = header.getOrDefault("X-Amz-Target")
  valid_402656644 = validateParameter(valid_402656644, JString, required = true, default = newJString(
      "AWSMigrationHub.ListDiscoveredResources"))
  if valid_402656644 != nil:
    section.add "X-Amz-Target", valid_402656644
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

proc call*(call_402656653: Call_ListDiscoveredResources_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists discovered resources associated with the given <code>MigrationTask</code>.
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

proc call*(call_402656654: Call_ListDiscoveredResources_402656639;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDiscoveredResources
  ## Lists discovered resources associated with the given <code>MigrationTask</code>.
  ##   
                                                                                     ## MaxResults: string
                                                                                     ##             
                                                                                     ## : 
                                                                                     ## Pagination 
                                                                                     ## limit
  ##   
                                                                                             ## body: JObject (required)
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  var query_402656655 = newJObject()
  var body_402656656 = newJObject()
  add(query_402656655, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656656 = body
  add(query_402656655, "NextToken", newJString(NextToken))
  result = call_402656654.call(nil, query_402656655, nil, nil, body_402656656)

var listDiscoveredResources* = Call_ListDiscoveredResources_402656639(
    name: "listDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.ListDiscoveredResources",
    validator: validate_ListDiscoveredResources_402656640, base: "/",
    makeUrl: url_ListDiscoveredResources_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMigrationTasks_402656657 = ref object of OpenApiRestCall_402656038
proc url_ListMigrationTasks_402656659(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMigrationTasks_402656658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists all, or filtered by resource name, migration tasks associated with the user account making this call. This API has the following traits:</p> <ul> <li> <p>Can show a summary list of the most recent migration tasks.</p> </li> <li> <p>Can show a summary list of migration tasks associated with a given discovered resource.</p> </li> <li> <p>Lists migration tasks in a paginated interface.</p> </li> </ul>
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
  var valid_402656660 = query.getOrDefault("MaxResults")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "MaxResults", valid_402656660
  var valid_402656661 = query.getOrDefault("NextToken")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "NextToken", valid_402656661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656662 = header.getOrDefault("X-Amz-Target")
  valid_402656662 = validateParameter(valid_402656662, JString, required = true, default = newJString(
      "AWSMigrationHub.ListMigrationTasks"))
  if valid_402656662 != nil:
    section.add "X-Amz-Target", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Security-Token", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Signature")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Signature", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Algorithm", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Date")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Date", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Credential")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Credential", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656669
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

proc call*(call_402656671: Call_ListMigrationTasks_402656657;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all, or filtered by resource name, migration tasks associated with the user account making this call. This API has the following traits:</p> <ul> <li> <p>Can show a summary list of the most recent migration tasks.</p> </li> <li> <p>Can show a summary list of migration tasks associated with a given discovered resource.</p> </li> <li> <p>Lists migration tasks in a paginated interface.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656671.validator(path, query, header, formData, body, _)
  let scheme = call_402656671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656671.makeUrl(scheme.get, call_402656671.host, call_402656671.base,
                                   call_402656671.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656671, uri, valid, _)

proc call*(call_402656672: Call_ListMigrationTasks_402656657; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMigrationTasks
  ## <p>Lists all, or filtered by resource name, migration tasks associated with the user account making this call. This API has the following traits:</p> <ul> <li> <p>Can show a summary list of the most recent migration tasks.</p> </li> <li> <p>Can show a summary list of migration tasks associated with a given discovered resource.</p> </li> <li> <p>Lists migration tasks in a paginated interface.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                               ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                               ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## token
  var query_402656673 = newJObject()
  var body_402656674 = newJObject()
  add(query_402656673, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656674 = body
  add(query_402656673, "NextToken", newJString(NextToken))
  result = call_402656672.call(nil, query_402656673, nil, nil, body_402656674)

var listMigrationTasks* = Call_ListMigrationTasks_402656657(
    name: "listMigrationTasks", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.ListMigrationTasks",
    validator: validate_ListMigrationTasks_402656658, base: "/",
    makeUrl: url_ListMigrationTasks_402656659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProgressUpdateStreams_402656675 = ref object of OpenApiRestCall_402656038
proc url_ListProgressUpdateStreams_402656677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProgressUpdateStreams_402656676(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists progress update streams associated with the user account making this call.
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
  var valid_402656678 = query.getOrDefault("MaxResults")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "MaxResults", valid_402656678
  var valid_402656679 = query.getOrDefault("NextToken")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "NextToken", valid_402656679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656680 = header.getOrDefault("X-Amz-Target")
  valid_402656680 = validateParameter(valid_402656680, JString, required = true, default = newJString(
      "AWSMigrationHub.ListProgressUpdateStreams"))
  if valid_402656680 != nil:
    section.add "X-Amz-Target", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Security-Token", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Signature")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Signature", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Algorithm", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Date")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Date", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Credential")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Credential", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656687
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

proc call*(call_402656689: Call_ListProgressUpdateStreams_402656675;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists progress update streams associated with the user account making this call.
                                                                                         ## 
  let valid = call_402656689.validator(path, query, header, formData, body, _)
  let scheme = call_402656689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656689.makeUrl(scheme.get, call_402656689.host, call_402656689.base,
                                   call_402656689.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656689, uri, valid, _)

proc call*(call_402656690: Call_ListProgressUpdateStreams_402656675;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProgressUpdateStreams
  ## Lists progress update streams associated with the user account making this call.
  ##   
                                                                                     ## MaxResults: string
                                                                                     ##             
                                                                                     ## : 
                                                                                     ## Pagination 
                                                                                     ## limit
  ##   
                                                                                             ## body: JObject (required)
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  var query_402656691 = newJObject()
  var body_402656692 = newJObject()
  add(query_402656691, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656692 = body
  add(query_402656691, "NextToken", newJString(NextToken))
  result = call_402656690.call(nil, query_402656691, nil, nil, body_402656692)

var listProgressUpdateStreams* = Call_ListProgressUpdateStreams_402656675(
    name: "listProgressUpdateStreams", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.ListProgressUpdateStreams",
    validator: validate_ListProgressUpdateStreams_402656676, base: "/",
    makeUrl: url_ListProgressUpdateStreams_402656677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyApplicationState_402656693 = ref object of OpenApiRestCall_402656038
proc url_NotifyApplicationState_402656695(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_NotifyApplicationState_402656694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the migration state of an application. For a given application identified by the value passed to <code>ApplicationId</code>, its status is set or updated by passing one of three values to <code>Status</code>: <code>NOT_STARTED | IN_PROGRESS | COMPLETED</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656696 = header.getOrDefault("X-Amz-Target")
  valid_402656696 = validateParameter(valid_402656696, JString, required = true, default = newJString(
      "AWSMigrationHub.NotifyApplicationState"))
  if valid_402656696 != nil:
    section.add "X-Amz-Target", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Security-Token", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Signature")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Signature", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Algorithm", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Date")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Date", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Credential")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Credential", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656703
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

proc call*(call_402656705: Call_NotifyApplicationState_402656693;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the migration state of an application. For a given application identified by the value passed to <code>ApplicationId</code>, its status is set or updated by passing one of three values to <code>Status</code>: <code>NOT_STARTED | IN_PROGRESS | COMPLETED</code>.
                                                                                         ## 
  let valid = call_402656705.validator(path, query, header, formData, body, _)
  let scheme = call_402656705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656705.makeUrl(scheme.get, call_402656705.host, call_402656705.base,
                                   call_402656705.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656705, uri, valid, _)

proc call*(call_402656706: Call_NotifyApplicationState_402656693; body: JsonNode): Recallable =
  ## notifyApplicationState
  ## Sets the migration state of an application. For a given application identified by the value passed to <code>ApplicationId</code>, its status is set or updated by passing one of three values to <code>Status</code>: <code>NOT_STARTED | IN_PROGRESS | COMPLETED</code>.
  ##   
                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656707 = newJObject()
  if body != nil:
    body_402656707 = body
  result = call_402656706.call(nil, nil, nil, nil, body_402656707)

var notifyApplicationState* = Call_NotifyApplicationState_402656693(
    name: "notifyApplicationState", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.NotifyApplicationState",
    validator: validate_NotifyApplicationState_402656694, base: "/",
    makeUrl: url_NotifyApplicationState_402656695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyMigrationTaskState_402656708 = ref object of OpenApiRestCall_402656038
proc url_NotifyMigrationTaskState_402656710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_NotifyMigrationTaskState_402656709(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Notifies Migration Hub of the current status, progress, or other detail regarding a migration task. This API has the following traits:</p> <ul> <li> <p>Migration tools will call the <code>NotifyMigrationTaskState</code> API to share the latest progress and status.</p> </li> <li> <p> <code>MigrationTaskName</code> is used for addressing updates to the correct target.</p> </li> <li> <p> <code>ProgressUpdateStream</code> is used for access control and to provide a namespace for each migration tool.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656711 = header.getOrDefault("X-Amz-Target")
  valid_402656711 = validateParameter(valid_402656711, JString, required = true, default = newJString(
      "AWSMigrationHub.NotifyMigrationTaskState"))
  if valid_402656711 != nil:
    section.add "X-Amz-Target", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Security-Token", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Signature")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Signature", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Algorithm", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Date")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Date", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Credential")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Credential", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656718
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

proc call*(call_402656720: Call_NotifyMigrationTaskState_402656708;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Notifies Migration Hub of the current status, progress, or other detail regarding a migration task. This API has the following traits:</p> <ul> <li> <p>Migration tools will call the <code>NotifyMigrationTaskState</code> API to share the latest progress and status.</p> </li> <li> <p> <code>MigrationTaskName</code> is used for addressing updates to the correct target.</p> </li> <li> <p> <code>ProgressUpdateStream</code> is used for access control and to provide a namespace for each migration tool.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656720.validator(path, query, header, formData, body, _)
  let scheme = call_402656720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656720.makeUrl(scheme.get, call_402656720.host, call_402656720.base,
                                   call_402656720.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656720, uri, valid, _)

proc call*(call_402656721: Call_NotifyMigrationTaskState_402656708;
           body: JsonNode): Recallable =
  ## notifyMigrationTaskState
  ## <p>Notifies Migration Hub of the current status, progress, or other detail regarding a migration task. This API has the following traits:</p> <ul> <li> <p>Migration tools will call the <code>NotifyMigrationTaskState</code> API to share the latest progress and status.</p> </li> <li> <p> <code>MigrationTaskName</code> is used for addressing updates to the correct target.</p> </li> <li> <p> <code>ProgressUpdateStream</code> is used for access control and to provide a namespace for each migration tool.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656722 = newJObject()
  if body != nil:
    body_402656722 = body
  result = call_402656721.call(nil, nil, nil, nil, body_402656722)

var notifyMigrationTaskState* = Call_NotifyMigrationTaskState_402656708(
    name: "notifyMigrationTaskState", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.NotifyMigrationTaskState",
    validator: validate_NotifyMigrationTaskState_402656709, base: "/",
    makeUrl: url_NotifyMigrationTaskState_402656710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourceAttributes_402656723 = ref object of OpenApiRestCall_402656038
proc url_PutResourceAttributes_402656725(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourceAttributes_402656724(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Provides identifying details of the resource being migrated so that it can be associated in the Application Discovery Service repository. This association occurs asynchronously after <code>PutResourceAttributes</code> returns.</p> <important> <ul> <li> <p>Keep in mind that subsequent calls to PutResourceAttributes will override previously stored attributes. For example, if it is first called with a MAC address, but later, it is desired to <i>add</i> an IP address, it will then be required to call it with <i>both</i> the IP and MAC addresses to prevent overriding the MAC address.</p> </li> <li> <p>Note the instructions regarding the special use case of the <a href="https://docs.aws.amazon.com/migrationhub/latest/ug/API_PutResourceAttributes.html#migrationhub-PutResourceAttributes-request-ResourceAttributeList"> <code>ResourceAttributeList</code> </a> parameter when specifying any "VM" related value.</p> </li> </ul> </important> <note> <p>Because this is an asynchronous call, it will always return 200, whether an association occurs or not. To confirm if an association was found based on the provided details, call <code>ListDiscoveredResources</code>.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656726 = header.getOrDefault("X-Amz-Target")
  valid_402656726 = validateParameter(valid_402656726, JString, required = true, default = newJString(
      "AWSMigrationHub.PutResourceAttributes"))
  if valid_402656726 != nil:
    section.add "X-Amz-Target", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Security-Token", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Signature")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Signature", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Algorithm", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Date")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Date", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Credential")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Credential", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656733
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

proc call*(call_402656735: Call_PutResourceAttributes_402656723;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provides identifying details of the resource being migrated so that it can be associated in the Application Discovery Service repository. This association occurs asynchronously after <code>PutResourceAttributes</code> returns.</p> <important> <ul> <li> <p>Keep in mind that subsequent calls to PutResourceAttributes will override previously stored attributes. For example, if it is first called with a MAC address, but later, it is desired to <i>add</i> an IP address, it will then be required to call it with <i>both</i> the IP and MAC addresses to prevent overriding the MAC address.</p> </li> <li> <p>Note the instructions regarding the special use case of the <a href="https://docs.aws.amazon.com/migrationhub/latest/ug/API_PutResourceAttributes.html#migrationhub-PutResourceAttributes-request-ResourceAttributeList"> <code>ResourceAttributeList</code> </a> parameter when specifying any "VM" related value.</p> </li> </ul> </important> <note> <p>Because this is an asynchronous call, it will always return 200, whether an association occurs or not. To confirm if an association was found based on the provided details, call <code>ListDiscoveredResources</code>.</p> </note>
                                                                                         ## 
  let valid = call_402656735.validator(path, query, header, formData, body, _)
  let scheme = call_402656735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656735.makeUrl(scheme.get, call_402656735.host, call_402656735.base,
                                   call_402656735.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656735, uri, valid, _)

proc call*(call_402656736: Call_PutResourceAttributes_402656723; body: JsonNode): Recallable =
  ## putResourceAttributes
  ## <p>Provides identifying details of the resource being migrated so that it can be associated in the Application Discovery Service repository. This association occurs asynchronously after <code>PutResourceAttributes</code> returns.</p> <important> <ul> <li> <p>Keep in mind that subsequent calls to PutResourceAttributes will override previously stored attributes. For example, if it is first called with a MAC address, but later, it is desired to <i>add</i> an IP address, it will then be required to call it with <i>both</i> the IP and MAC addresses to prevent overriding the MAC address.</p> </li> <li> <p>Note the instructions regarding the special use case of the <a href="https://docs.aws.amazon.com/migrationhub/latest/ug/API_PutResourceAttributes.html#migrationhub-PutResourceAttributes-request-ResourceAttributeList"> <code>ResourceAttributeList</code> </a> parameter when specifying any "VM" related value.</p> </li> </ul> </important> <note> <p>Because this is an asynchronous call, it will always return 200, whether an association occurs or not. To confirm if an association was found based on the provided details, call <code>ListDiscoveredResources</code>.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656737 = newJObject()
  if body != nil:
    body_402656737 = body
  result = call_402656736.call(nil, nil, nil, nil, body_402656737)

var putResourceAttributes* = Call_PutResourceAttributes_402656723(
    name: "putResourceAttributes", meth: HttpMethod.HttpPost,
    host: "mgh.amazonaws.com",
    route: "/#X-Amz-Target=AWSMigrationHub.PutResourceAttributes",
    validator: validate_PutResourceAttributes_402656724, base: "/",
    makeUrl: url_PutResourceAttributes_402656725,
    schemes: {Scheme.Https, Scheme.Http})
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