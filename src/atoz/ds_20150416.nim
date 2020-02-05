
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Directory Service
## version: 2015-04-16
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Directory Service</fullname> <p>AWS Directory Service is a web service that makes it easy for you to setup and run directories in the AWS cloud, or connect your AWS resources with an existing on-premises Microsoft Active Directory. This guide provides detailed information about AWS Directory Service operations, data types, parameters, and errors. For information about AWS Directory Services features, see <a href="https://aws.amazon.com/directoryservice/">AWS Directory Service</a> and the <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/what_is.html">AWS Directory Service Administration Guide</a>.</p> <note> <p>AWS provides SDKs that consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .Net, iOS, Android, etc.). The SDKs provide a convenient way to create programmatic access to AWS Directory Service and other AWS services. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ds/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ds.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "ds.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ds.us-west-2.amazonaws.com",
                           "eu-west-2": "ds.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "ds.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ds.eu-central-1.amazonaws.com",
                           "us-east-2": "ds.us-east-2.amazonaws.com",
                           "us-east-1": "ds.us-east-1.amazonaws.com", "cn-northwest-1": "ds.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ds.ap-south-1.amazonaws.com",
                           "eu-north-1": "ds.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "ds.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ds.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ds.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ds.eu-west-3.amazonaws.com",
                           "cn-north-1": "ds.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ds.sa-east-1.amazonaws.com",
                           "eu-west-1": "ds.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ds.us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "ds.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ds.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ds.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ds.ap-southeast-1.amazonaws.com",
      "us-west-2": "ds.us-west-2.amazonaws.com",
      "eu-west-2": "ds.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ds.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ds.eu-central-1.amazonaws.com",
      "us-east-2": "ds.us-east-2.amazonaws.com",
      "us-east-1": "ds.us-east-1.amazonaws.com",
      "cn-northwest-1": "ds.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ds.ap-south-1.amazonaws.com",
      "eu-north-1": "ds.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ds.ap-northeast-2.amazonaws.com",
      "us-west-1": "ds.us-west-1.amazonaws.com",
      "us-gov-east-1": "ds.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ds.eu-west-3.amazonaws.com",
      "cn-north-1": "ds.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ds.sa-east-1.amazonaws.com",
      "eu-west-1": "ds.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ds.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ds.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ds.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ds"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptSharedDirectory_612996 = ref object of OpenApiRestCall_612658
proc url_AcceptSharedDirectory_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptSharedDirectory_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Accepts a directory sharing request that was sent from the directory owner account.
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
      "DirectoryService_20150416.AcceptSharedDirectory"))
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

proc call*(call_613154: Call_AcceptSharedDirectory_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AcceptSharedDirectory_612996; body: JsonNode): Recallable =
  ## acceptSharedDirectory
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var acceptSharedDirectory* = Call_AcceptSharedDirectory_612996(
    name: "acceptSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AcceptSharedDirectory",
    validator: validate_AcceptSharedDirectory_612997, base: "/",
    url: url_AcceptSharedDirectory_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddIpRoutes_613265 = ref object of OpenApiRestCall_612658
proc url_AddIpRoutes_613267(protocol: Scheme; host: string; base: string;
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

proc validate_AddIpRoutes_613266(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
      "DirectoryService_20150416.AddIpRoutes"))
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

proc call*(call_613277: Call_AddIpRoutes_613265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AddIpRoutes_613265; body: JsonNode): Recallable =
  ## addIpRoutes
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var addIpRoutes* = Call_AddIpRoutes_613265(name: "addIpRoutes",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.AddIpRoutes",
                                        validator: validate_AddIpRoutes_613266,
                                        base: "/", url: url_AddIpRoutes_613267,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_613280 = ref object of OpenApiRestCall_612658
proc url_AddTagsToResource_613282(protocol: Scheme; host: string; base: string;
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

proc validate_AddTagsToResource_613281(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
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
      "DirectoryService_20150416.AddTagsToResource"))
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

proc call*(call_613292: Call_AddTagsToResource_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_AddTagsToResource_613280; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var addTagsToResource* = Call_AddTagsToResource_613280(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AddTagsToResource",
    validator: validate_AddTagsToResource_613281, base: "/",
    url: url_AddTagsToResource_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSchemaExtension_613295 = ref object of OpenApiRestCall_612658
proc url_CancelSchemaExtension_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CancelSchemaExtension_613296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
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
      "DirectoryService_20150416.CancelSchemaExtension"))
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

proc call*(call_613307: Call_CancelSchemaExtension_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CancelSchemaExtension_613295; body: JsonNode): Recallable =
  ## cancelSchemaExtension
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var cancelSchemaExtension* = Call_CancelSchemaExtension_613295(
    name: "cancelSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CancelSchemaExtension",
    validator: validate_CancelSchemaExtension_613296, base: "/",
    url: url_CancelSchemaExtension_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectDirectory_613310 = ref object of OpenApiRestCall_612658
proc url_ConnectDirectory_613312(protocol: Scheme; host: string; base: string;
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

proc validate_ConnectDirectory_613311(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
      "DirectoryService_20150416.ConnectDirectory"))
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

proc call*(call_613322: Call_ConnectDirectory_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_ConnectDirectory_613310; body: JsonNode): Recallable =
  ## connectDirectory
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var connectDirectory* = Call_ConnectDirectory_613310(name: "connectDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ConnectDirectory",
    validator: validate_ConnectDirectory_613311, base: "/",
    url: url_ConnectDirectory_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_613325 = ref object of OpenApiRestCall_612658
proc url_CreateAlias_613327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlias_613326(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
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
      "DirectoryService_20150416.CreateAlias"))
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

proc call*(call_613337: Call_CreateAlias_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateAlias_613325; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createAlias* = Call_CreateAlias_613325(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateAlias",
                                        validator: validate_CreateAlias_613326,
                                        base: "/", url: url_CreateAlias_613327,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputer_613340 = ref object of OpenApiRestCall_612658
proc url_CreateComputer_613342(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComputer_613341(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
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
      "DirectoryService_20150416.CreateComputer"))
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

proc call*(call_613352: Call_CreateComputer_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_CreateComputer_613340; body: JsonNode): Recallable =
  ## createComputer
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var createComputer* = Call_CreateComputer_613340(name: "createComputer",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateComputer",
    validator: validate_CreateComputer_613341, base: "/", url: url_CreateComputer_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConditionalForwarder_613355 = ref object of OpenApiRestCall_612658
proc url_CreateConditionalForwarder_613357(protocol: Scheme; host: string;
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

proc validate_CreateConditionalForwarder_613356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateConditionalForwarder"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_CreateConditionalForwarder_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_CreateConditionalForwarder_613355; body: JsonNode): Recallable =
  ## createConditionalForwarder
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var createConditionalForwarder* = Call_CreateConditionalForwarder_613355(
    name: "createConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateConditionalForwarder",
    validator: validate_CreateConditionalForwarder_613356, base: "/",
    url: url_CreateConditionalForwarder_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_613370 = ref object of OpenApiRestCall_612658
proc url_CreateDirectory_613372(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDirectory_613371(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateDirectory"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_CreateDirectory_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CreateDirectory_613370; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var createDirectory* = Call_CreateDirectory_613370(name: "createDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateDirectory",
    validator: validate_CreateDirectory_613371, base: "/", url: url_CreateDirectory_613372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogSubscription_613385 = ref object of OpenApiRestCall_612658
proc url_CreateLogSubscription_613387(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLogSubscription_613386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateLogSubscription"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_CreateLogSubscription_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_CreateLogSubscription_613385; body: JsonNode): Recallable =
  ## createLogSubscription
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var createLogSubscription* = Call_CreateLogSubscription_613385(
    name: "createLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateLogSubscription",
    validator: validate_CreateLogSubscription_613386, base: "/",
    url: url_CreateLogSubscription_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMicrosoftAD_613400 = ref object of OpenApiRestCall_612658
proc url_CreateMicrosoftAD_613402(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMicrosoftAD_613401(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateMicrosoftAD"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_CreateMicrosoftAD_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_CreateMicrosoftAD_613400; body: JsonNode): Recallable =
  ## createMicrosoftAD
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var createMicrosoftAD* = Call_CreateMicrosoftAD_613400(name: "createMicrosoftAD",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateMicrosoftAD",
    validator: validate_CreateMicrosoftAD_613401, base: "/",
    url: url_CreateMicrosoftAD_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_613415 = ref object of OpenApiRestCall_612658
proc url_CreateSnapshot_613417(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSnapshot_613416(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateSnapshot"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_CreateSnapshot_613415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_CreateSnapshot_613415; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var createSnapshot* = Call_CreateSnapshot_613415(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateSnapshot",
    validator: validate_CreateSnapshot_613416, base: "/", url: url_CreateSnapshot_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrust_613430 = ref object of OpenApiRestCall_612658
proc url_CreateTrust_613432(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrust_613431(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateTrust"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CreateTrust_613430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CreateTrust_613430; body: JsonNode): Recallable =
  ## createTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var createTrust* = Call_CreateTrust_613430(name: "createTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateTrust",
                                        validator: validate_CreateTrust_613431,
                                        base: "/", url: url_CreateTrust_613432,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConditionalForwarder_613445 = ref object of OpenApiRestCall_612658
proc url_DeleteConditionalForwarder_613447(protocol: Scheme; host: string;
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

proc validate_DeleteConditionalForwarder_613446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteConditionalForwarder"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_DeleteConditionalForwarder_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_DeleteConditionalForwarder_613445; body: JsonNode): Recallable =
  ## deleteConditionalForwarder
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var deleteConditionalForwarder* = Call_DeleteConditionalForwarder_613445(
    name: "deleteConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteConditionalForwarder",
    validator: validate_DeleteConditionalForwarder_613446, base: "/",
    url: url_DeleteConditionalForwarder_613447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_613460 = ref object of OpenApiRestCall_612658
proc url_DeleteDirectory_613462(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDirectory_613461(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteDirectory"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_DeleteDirectory_613460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_DeleteDirectory_613460; body: JsonNode): Recallable =
  ## deleteDirectory
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var deleteDirectory* = Call_DeleteDirectory_613460(name: "deleteDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteDirectory",
    validator: validate_DeleteDirectory_613461, base: "/", url: url_DeleteDirectory_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogSubscription_613475 = ref object of OpenApiRestCall_612658
proc url_DeleteLogSubscription_613477(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLogSubscription_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified log subscription.
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
  var valid_613478 = header.getOrDefault("X-Amz-Target")
  valid_613478 = validateParameter(valid_613478, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteLogSubscription"))
  if valid_613478 != nil:
    section.add "X-Amz-Target", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_DeleteLogSubscription_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log subscription.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_DeleteLogSubscription_613475; body: JsonNode): Recallable =
  ## deleteLogSubscription
  ## Deletes the specified log subscription.
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var deleteLogSubscription* = Call_DeleteLogSubscription_613475(
    name: "deleteLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteLogSubscription",
    validator: validate_DeleteLogSubscription_613476, base: "/",
    url: url_DeleteLogSubscription_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshot_613490 = ref object of OpenApiRestCall_612658
proc url_DeleteSnapshot_613492(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSnapshot_613491(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a directory snapshot.
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
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteSnapshot"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_DeleteSnapshot_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory snapshot.
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_DeleteSnapshot_613490; body: JsonNode): Recallable =
  ## deleteSnapshot
  ## Deletes a directory snapshot.
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var deleteSnapshot* = Call_DeleteSnapshot_613490(name: "deleteSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteSnapshot",
    validator: validate_DeleteSnapshot_613491, base: "/", url: url_DeleteSnapshot_613492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrust_613505 = ref object of OpenApiRestCall_612658
proc url_DeleteTrust_613507(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrust_613506(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
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
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteTrust"))
  if valid_613508 != nil:
    section.add "X-Amz-Target", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_DeleteTrust_613505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_DeleteTrust_613505; body: JsonNode): Recallable =
  ## deleteTrust
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var deleteTrust* = Call_DeleteTrust_613505(name: "deleteTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteTrust",
                                        validator: validate_DeleteTrust_613506,
                                        base: "/", url: url_DeleteTrust_613507,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterCertificate_613520 = ref object of OpenApiRestCall_612658
proc url_DeregisterCertificate_613522(protocol: Scheme; host: string; base: string;
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

proc validate_DeregisterCertificate_613521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
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
  var valid_613523 = header.getOrDefault("X-Amz-Target")
  valid_613523 = validateParameter(valid_613523, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterCertificate"))
  if valid_613523 != nil:
    section.add "X-Amz-Target", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_DeregisterCertificate_613520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_DeregisterCertificate_613520; body: JsonNode): Recallable =
  ## deregisterCertificate
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var deregisterCertificate* = Call_DeregisterCertificate_613520(
    name: "deregisterCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterCertificate",
    validator: validate_DeregisterCertificate_613521, base: "/",
    url: url_DeregisterCertificate_613522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterEventTopic_613535 = ref object of OpenApiRestCall_612658
proc url_DeregisterEventTopic_613537(protocol: Scheme; host: string; base: string;
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

proc validate_DeregisterEventTopic_613536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified directory as a publisher to the specified SNS topic.
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
  var valid_613538 = header.getOrDefault("X-Amz-Target")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterEventTopic"))
  if valid_613538 != nil:
    section.add "X-Amz-Target", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613547: Call_DeregisterEventTopic_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ## 
  let valid = call_613547.validator(path, query, header, formData, body)
  let scheme = call_613547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613547.url(scheme.get, call_613547.host, call_613547.base,
                         call_613547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613547, url, valid)

proc call*(call_613548: Call_DeregisterEventTopic_613535; body: JsonNode): Recallable =
  ## deregisterEventTopic
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ##   body: JObject (required)
  var body_613549 = newJObject()
  if body != nil:
    body_613549 = body
  result = call_613548.call(nil, nil, nil, nil, body_613549)

var deregisterEventTopic* = Call_DeregisterEventTopic_613535(
    name: "deregisterEventTopic", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterEventTopic",
    validator: validate_DeregisterEventTopic_613536, base: "/",
    url: url_DeregisterEventTopic_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificate_613550 = ref object of OpenApiRestCall_612658
proc url_DescribeCertificate_613552(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCertificate_613551(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Displays information about the certificate registered for a secured LDAP connection.
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
  var valid_613553 = header.getOrDefault("X-Amz-Target")
  valid_613553 = validateParameter(valid_613553, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeCertificate"))
  if valid_613553 != nil:
    section.add "X-Amz-Target", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Signature")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Signature", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Content-Sha256", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Date")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Date", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Credential")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Credential", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Security-Token")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Security-Token", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Algorithm")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Algorithm", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-SignedHeaders", valid_613560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_DescribeCertificate_613550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays information about the certificate registered for a secured LDAP connection.
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_DescribeCertificate_613550; body: JsonNode): Recallable =
  ## describeCertificate
  ## Displays information about the certificate registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_613564 = newJObject()
  if body != nil:
    body_613564 = body
  result = call_613563.call(nil, nil, nil, nil, body_613564)

var describeCertificate* = Call_DescribeCertificate_613550(
    name: "describeCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeCertificate",
    validator: validate_DescribeCertificate_613551, base: "/",
    url: url_DescribeCertificate_613552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConditionalForwarders_613565 = ref object of OpenApiRestCall_612658
proc url_DescribeConditionalForwarders_613567(protocol: Scheme; host: string;
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

proc validate_DescribeConditionalForwarders_613566(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeConditionalForwarders"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_DescribeConditionalForwarders_613565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_DescribeConditionalForwarders_613565; body: JsonNode): Recallable =
  ## describeConditionalForwarders
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var describeConditionalForwarders* = Call_DescribeConditionalForwarders_613565(
    name: "describeConditionalForwarders", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeConditionalForwarders",
    validator: validate_DescribeConditionalForwarders_613566, base: "/",
    url: url_DescribeConditionalForwarders_613567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectories_613580 = ref object of OpenApiRestCall_612658
proc url_DescribeDirectories_613582(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDirectories_613581(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
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
  var valid_613583 = header.getOrDefault("X-Amz-Target")
  valid_613583 = validateParameter(valid_613583, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDirectories"))
  if valid_613583 != nil:
    section.add "X-Amz-Target", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_DescribeDirectories_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_DescribeDirectories_613580; body: JsonNode): Recallable =
  ## describeDirectories
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ##   body: JObject (required)
  var body_613594 = newJObject()
  if body != nil:
    body_613594 = body
  result = call_613593.call(nil, nil, nil, nil, body_613594)

var describeDirectories* = Call_DescribeDirectories_613580(
    name: "describeDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDirectories",
    validator: validate_DescribeDirectories_613581, base: "/",
    url: url_DescribeDirectories_613582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomainControllers_613595 = ref object of OpenApiRestCall_612658
proc url_DescribeDomainControllers_613597(protocol: Scheme; host: string;
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

proc validate_DescribeDomainControllers_613596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information about any domain controllers in your directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_613598 = query.getOrDefault("NextToken")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "NextToken", valid_613598
  var valid_613599 = query.getOrDefault("Limit")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "Limit", valid_613599
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
  var valid_613600 = header.getOrDefault("X-Amz-Target")
  valid_613600 = validateParameter(valid_613600, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDomainControllers"))
  if valid_613600 != nil:
    section.add "X-Amz-Target", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Signature")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Signature", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Content-Sha256", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Date")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Date", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Credential")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Credential", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Security-Token")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Security-Token", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Algorithm")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Algorithm", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-SignedHeaders", valid_613607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613609: Call_DescribeDomainControllers_613595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about any domain controllers in your directory.
  ## 
  let valid = call_613609.validator(path, query, header, formData, body)
  let scheme = call_613609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613609.url(scheme.get, call_613609.host, call_613609.base,
                         call_613609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613609, url, valid)

proc call*(call_613610: Call_DescribeDomainControllers_613595; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeDomainControllers
  ## Provides information about any domain controllers in your directory.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_613611 = newJObject()
  var body_613612 = newJObject()
  add(query_613611, "NextToken", newJString(NextToken))
  add(query_613611, "Limit", newJString(Limit))
  if body != nil:
    body_613612 = body
  result = call_613610.call(nil, query_613611, nil, nil, body_613612)

var describeDomainControllers* = Call_DescribeDomainControllers_613595(
    name: "describeDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDomainControllers",
    validator: validate_DescribeDomainControllers_613596, base: "/",
    url: url_DescribeDomainControllers_613597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTopics_613614 = ref object of OpenApiRestCall_612658
proc url_DescribeEventTopics_613616(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventTopics_613615(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
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
  var valid_613617 = header.getOrDefault("X-Amz-Target")
  valid_613617 = validateParameter(valid_613617, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeEventTopics"))
  if valid_613617 != nil:
    section.add "X-Amz-Target", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Signature")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Signature", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Content-Sha256", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Date")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Date", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Credential")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Credential", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Security-Token")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Security-Token", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Algorithm")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Algorithm", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-SignedHeaders", valid_613624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613626: Call_DescribeEventTopics_613614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ## 
  let valid = call_613626.validator(path, query, header, formData, body)
  let scheme = call_613626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613626.url(scheme.get, call_613626.host, call_613626.base,
                         call_613626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613626, url, valid)

proc call*(call_613627: Call_DescribeEventTopics_613614; body: JsonNode): Recallable =
  ## describeEventTopics
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ##   body: JObject (required)
  var body_613628 = newJObject()
  if body != nil:
    body_613628 = body
  result = call_613627.call(nil, nil, nil, nil, body_613628)

var describeEventTopics* = Call_DescribeEventTopics_613614(
    name: "describeEventTopics", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeEventTopics",
    validator: validate_DescribeEventTopics_613615, base: "/",
    url: url_DescribeEventTopics_613616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLDAPSSettings_613629 = ref object of OpenApiRestCall_612658
proc url_DescribeLDAPSSettings_613631(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLDAPSSettings_613630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the status of LDAP security for the specified directory.
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
  var valid_613632 = header.getOrDefault("X-Amz-Target")
  valid_613632 = validateParameter(valid_613632, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeLDAPSSettings"))
  if valid_613632 != nil:
    section.add "X-Amz-Target", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Signature")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Signature", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Content-Sha256", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Date")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Date", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Credential")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Credential", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Security-Token")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Security-Token", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Algorithm")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Algorithm", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-SignedHeaders", valid_613639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613641: Call_DescribeLDAPSSettings_613629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of LDAP security for the specified directory.
  ## 
  let valid = call_613641.validator(path, query, header, formData, body)
  let scheme = call_613641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613641.url(scheme.get, call_613641.host, call_613641.base,
                         call_613641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613641, url, valid)

proc call*(call_613642: Call_DescribeLDAPSSettings_613629; body: JsonNode): Recallable =
  ## describeLDAPSSettings
  ## Describes the status of LDAP security for the specified directory.
  ##   body: JObject (required)
  var body_613643 = newJObject()
  if body != nil:
    body_613643 = body
  result = call_613642.call(nil, nil, nil, nil, body_613643)

var describeLDAPSSettings* = Call_DescribeLDAPSSettings_613629(
    name: "describeLDAPSSettings", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeLDAPSSettings",
    validator: validate_DescribeLDAPSSettings_613630, base: "/",
    url: url_DescribeLDAPSSettings_613631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSharedDirectories_613644 = ref object of OpenApiRestCall_612658
proc url_DescribeSharedDirectories_613646(protocol: Scheme; host: string;
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

proc validate_DescribeSharedDirectories_613645(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the shared directories in your account. 
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
  var valid_613647 = header.getOrDefault("X-Amz-Target")
  valid_613647 = validateParameter(valid_613647, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSharedDirectories"))
  if valid_613647 != nil:
    section.add "X-Amz-Target", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Signature")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Signature", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Content-Sha256", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Date")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Date", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Credential")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Credential", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Security-Token")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Security-Token", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Algorithm")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Algorithm", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-SignedHeaders", valid_613654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613656: Call_DescribeSharedDirectories_613644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the shared directories in your account. 
  ## 
  let valid = call_613656.validator(path, query, header, formData, body)
  let scheme = call_613656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613656.url(scheme.get, call_613656.host, call_613656.base,
                         call_613656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613656, url, valid)

proc call*(call_613657: Call_DescribeSharedDirectories_613644; body: JsonNode): Recallable =
  ## describeSharedDirectories
  ## Returns the shared directories in your account. 
  ##   body: JObject (required)
  var body_613658 = newJObject()
  if body != nil:
    body_613658 = body
  result = call_613657.call(nil, nil, nil, nil, body_613658)

var describeSharedDirectories* = Call_DescribeSharedDirectories_613644(
    name: "describeSharedDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSharedDirectories",
    validator: validate_DescribeSharedDirectories_613645, base: "/",
    url: url_DescribeSharedDirectories_613646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshots_613659 = ref object of OpenApiRestCall_612658
proc url_DescribeSnapshots_613661(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSnapshots_613660(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
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
  var valid_613662 = header.getOrDefault("X-Amz-Target")
  valid_613662 = validateParameter(valid_613662, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSnapshots"))
  if valid_613662 != nil:
    section.add "X-Amz-Target", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613671: Call_DescribeSnapshots_613659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ## 
  let valid = call_613671.validator(path, query, header, formData, body)
  let scheme = call_613671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613671.url(scheme.get, call_613671.host, call_613671.base,
                         call_613671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613671, url, valid)

proc call*(call_613672: Call_DescribeSnapshots_613659; body: JsonNode): Recallable =
  ## describeSnapshots
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ##   body: JObject (required)
  var body_613673 = newJObject()
  if body != nil:
    body_613673 = body
  result = call_613672.call(nil, nil, nil, nil, body_613673)

var describeSnapshots* = Call_DescribeSnapshots_613659(name: "describeSnapshots",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSnapshots",
    validator: validate_DescribeSnapshots_613660, base: "/",
    url: url_DescribeSnapshots_613661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrusts_613674 = ref object of OpenApiRestCall_612658
proc url_DescribeTrusts_613676(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrusts_613675(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
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
  var valid_613677 = header.getOrDefault("X-Amz-Target")
  valid_613677 = validateParameter(valid_613677, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeTrusts"))
  if valid_613677 != nil:
    section.add "X-Amz-Target", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Signature")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Signature", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Content-Sha256", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Date")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Date", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Credential")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Credential", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Security-Token")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Security-Token", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Algorithm")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Algorithm", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-SignedHeaders", valid_613684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613686: Call_DescribeTrusts_613674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ## 
  let valid = call_613686.validator(path, query, header, formData, body)
  let scheme = call_613686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613686.url(scheme.get, call_613686.host, call_613686.base,
                         call_613686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613686, url, valid)

proc call*(call_613687: Call_DescribeTrusts_613674; body: JsonNode): Recallable =
  ## describeTrusts
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ##   body: JObject (required)
  var body_613688 = newJObject()
  if body != nil:
    body_613688 = body
  result = call_613687.call(nil, nil, nil, nil, body_613688)

var describeTrusts* = Call_DescribeTrusts_613674(name: "describeTrusts",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeTrusts",
    validator: validate_DescribeTrusts_613675, base: "/", url: url_DescribeTrusts_613676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableLDAPS_613689 = ref object of OpenApiRestCall_612658
proc url_DisableLDAPS_613691(protocol: Scheme; host: string; base: string;
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

proc validate_DisableLDAPS_613690(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deactivates LDAP secure calls for the specified directory.
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
  var valid_613692 = header.getOrDefault("X-Amz-Target")
  valid_613692 = validateParameter(valid_613692, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableLDAPS"))
  if valid_613692 != nil:
    section.add "X-Amz-Target", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Signature")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Signature", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Content-Sha256", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Date")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Date", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Credential")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Credential", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Security-Token")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Security-Token", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Algorithm")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Algorithm", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-SignedHeaders", valid_613699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613701: Call_DisableLDAPS_613689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates LDAP secure calls for the specified directory.
  ## 
  let valid = call_613701.validator(path, query, header, formData, body)
  let scheme = call_613701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613701.url(scheme.get, call_613701.host, call_613701.base,
                         call_613701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613701, url, valid)

proc call*(call_613702: Call_DisableLDAPS_613689; body: JsonNode): Recallable =
  ## disableLDAPS
  ## Deactivates LDAP secure calls for the specified directory.
  ##   body: JObject (required)
  var body_613703 = newJObject()
  if body != nil:
    body_613703 = body
  result = call_613702.call(nil, nil, nil, nil, body_613703)

var disableLDAPS* = Call_DisableLDAPS_613689(name: "disableLDAPS",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableLDAPS",
    validator: validate_DisableLDAPS_613690, base: "/", url: url_DisableLDAPS_613691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableRadius_613704 = ref object of OpenApiRestCall_612658
proc url_DisableRadius_613706(protocol: Scheme; host: string; base: string;
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

proc validate_DisableRadius_613705(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
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
  var valid_613707 = header.getOrDefault("X-Amz-Target")
  valid_613707 = validateParameter(valid_613707, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableRadius"))
  if valid_613707 != nil:
    section.add "X-Amz-Target", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Signature")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Signature", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Content-Sha256", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Date")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Date", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Credential")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Credential", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Security-Token")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Security-Token", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Algorithm")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Algorithm", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-SignedHeaders", valid_613714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_DisableRadius_613704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_DisableRadius_613704; body: JsonNode): Recallable =
  ## disableRadius
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_613718 = newJObject()
  if body != nil:
    body_613718 = body
  result = call_613717.call(nil, nil, nil, nil, body_613718)

var disableRadius* = Call_DisableRadius_613704(name: "disableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableRadius",
    validator: validate_DisableRadius_613705, base: "/", url: url_DisableRadius_613706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSso_613719 = ref object of OpenApiRestCall_612658
proc url_DisableSso_613721(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableSso_613720(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables single-sign on for a directory.
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
  var valid_613722 = header.getOrDefault("X-Amz-Target")
  valid_613722 = validateParameter(valid_613722, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableSso"))
  if valid_613722 != nil:
    section.add "X-Amz-Target", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Signature")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Signature", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Content-Sha256", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Date")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Date", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Credential")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Credential", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Security-Token")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Security-Token", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Algorithm")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Algorithm", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-SignedHeaders", valid_613729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_DisableSso_613719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables single-sign on for a directory.
  ## 
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_DisableSso_613719; body: JsonNode): Recallable =
  ## disableSso
  ## Disables single-sign on for a directory.
  ##   body: JObject (required)
  var body_613733 = newJObject()
  if body != nil:
    body_613733 = body
  result = call_613732.call(nil, nil, nil, nil, body_613733)

var disableSso* = Call_DisableSso_613719(name: "disableSso",
                                      meth: HttpMethod.HttpPost,
                                      host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DisableSso",
                                      validator: validate_DisableSso_613720,
                                      base: "/", url: url_DisableSso_613721,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableLDAPS_613734 = ref object of OpenApiRestCall_612658
proc url_EnableLDAPS_613736(protocol: Scheme; host: string; base: string;
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

proc validate_EnableLDAPS_613735(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Activates the switch for the specific directory to always use LDAP secure calls.
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
  var valid_613737 = header.getOrDefault("X-Amz-Target")
  valid_613737 = validateParameter(valid_613737, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableLDAPS"))
  if valid_613737 != nil:
    section.add "X-Amz-Target", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Signature")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Signature", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Content-Sha256", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Date")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Date", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Credential")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Credential", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Security-Token")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Security-Token", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Algorithm")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Algorithm", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-SignedHeaders", valid_613744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613746: Call_EnableLDAPS_613734; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the switch for the specific directory to always use LDAP secure calls.
  ## 
  let valid = call_613746.validator(path, query, header, formData, body)
  let scheme = call_613746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613746.url(scheme.get, call_613746.host, call_613746.base,
                         call_613746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613746, url, valid)

proc call*(call_613747: Call_EnableLDAPS_613734; body: JsonNode): Recallable =
  ## enableLDAPS
  ## Activates the switch for the specific directory to always use LDAP secure calls.
  ##   body: JObject (required)
  var body_613748 = newJObject()
  if body != nil:
    body_613748 = body
  result = call_613747.call(nil, nil, nil, nil, body_613748)

var enableLDAPS* = Call_EnableLDAPS_613734(name: "enableLDAPS",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableLDAPS",
                                        validator: validate_EnableLDAPS_613735,
                                        base: "/", url: url_EnableLDAPS_613736,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableRadius_613749 = ref object of OpenApiRestCall_612658
proc url_EnableRadius_613751(protocol: Scheme; host: string; base: string;
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

proc validate_EnableRadius_613750(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
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
  var valid_613752 = header.getOrDefault("X-Amz-Target")
  valid_613752 = validateParameter(valid_613752, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableRadius"))
  if valid_613752 != nil:
    section.add "X-Amz-Target", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Signature")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Signature", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Content-Sha256", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Date")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Date", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Credential")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Credential", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Security-Token")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Security-Token", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Algorithm")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Algorithm", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-SignedHeaders", valid_613759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613761: Call_EnableRadius_613749; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_613761.validator(path, query, header, formData, body)
  let scheme = call_613761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613761.url(scheme.get, call_613761.host, call_613761.base,
                         call_613761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613761, url, valid)

proc call*(call_613762: Call_EnableRadius_613749; body: JsonNode): Recallable =
  ## enableRadius
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_613763 = newJObject()
  if body != nil:
    body_613763 = body
  result = call_613762.call(nil, nil, nil, nil, body_613763)

var enableRadius* = Call_EnableRadius_613749(name: "enableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.EnableRadius",
    validator: validate_EnableRadius_613750, base: "/", url: url_EnableRadius_613751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSso_613764 = ref object of OpenApiRestCall_612658
proc url_EnableSso_613766(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSso_613765(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
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
  var valid_613767 = header.getOrDefault("X-Amz-Target")
  valid_613767 = validateParameter(valid_613767, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableSso"))
  if valid_613767 != nil:
    section.add "X-Amz-Target", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Signature")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Signature", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Content-Sha256", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Date")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Date", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Credential")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Credential", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Security-Token")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Security-Token", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Algorithm")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Algorithm", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-SignedHeaders", valid_613774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613776: Call_EnableSso_613764; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
  ## 
  let valid = call_613776.validator(path, query, header, formData, body)
  let scheme = call_613776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613776.url(scheme.get, call_613776.host, call_613776.base,
                         call_613776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613776, url, valid)

proc call*(call_613777: Call_EnableSso_613764; body: JsonNode): Recallable =
  ## enableSso
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
  ##   body: JObject (required)
  var body_613778 = newJObject()
  if body != nil:
    body_613778 = body
  result = call_613777.call(nil, nil, nil, nil, body_613778)

var enableSso* = Call_EnableSso_613764(name: "enableSso", meth: HttpMethod.HttpPost,
                                    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableSso",
                                    validator: validate_EnableSso_613765,
                                    base: "/", url: url_EnableSso_613766,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectoryLimits_613779 = ref object of OpenApiRestCall_612658
proc url_GetDirectoryLimits_613781(protocol: Scheme; host: string; base: string;
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

proc validate_GetDirectoryLimits_613780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Obtains directory limit information for the current Region.
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
  var valid_613782 = header.getOrDefault("X-Amz-Target")
  valid_613782 = validateParameter(valid_613782, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetDirectoryLimits"))
  if valid_613782 != nil:
    section.add "X-Amz-Target", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Signature")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Signature", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Content-Sha256", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Date")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Date", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Credential")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Credential", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Security-Token")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Security-Token", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Algorithm")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Algorithm", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-SignedHeaders", valid_613789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613791: Call_GetDirectoryLimits_613779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains directory limit information for the current Region.
  ## 
  let valid = call_613791.validator(path, query, header, formData, body)
  let scheme = call_613791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613791.url(scheme.get, call_613791.host, call_613791.base,
                         call_613791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613791, url, valid)

proc call*(call_613792: Call_GetDirectoryLimits_613779; body: JsonNode): Recallable =
  ## getDirectoryLimits
  ## Obtains directory limit information for the current Region.
  ##   body: JObject (required)
  var body_613793 = newJObject()
  if body != nil:
    body_613793 = body
  result = call_613792.call(nil, nil, nil, nil, body_613793)

var getDirectoryLimits* = Call_GetDirectoryLimits_613779(
    name: "getDirectoryLimits", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetDirectoryLimits",
    validator: validate_GetDirectoryLimits_613780, base: "/",
    url: url_GetDirectoryLimits_613781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnapshotLimits_613794 = ref object of OpenApiRestCall_612658
proc url_GetSnapshotLimits_613796(protocol: Scheme; host: string; base: string;
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

proc validate_GetSnapshotLimits_613795(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Obtains the manual snapshot limits for a directory.
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
  var valid_613797 = header.getOrDefault("X-Amz-Target")
  valid_613797 = validateParameter(valid_613797, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetSnapshotLimits"))
  if valid_613797 != nil:
    section.add "X-Amz-Target", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Signature")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Signature", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Content-Sha256", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Date")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Date", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Credential")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Credential", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Security-Token")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Security-Token", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Algorithm")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Algorithm", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-SignedHeaders", valid_613804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613806: Call_GetSnapshotLimits_613794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains the manual snapshot limits for a directory.
  ## 
  let valid = call_613806.validator(path, query, header, formData, body)
  let scheme = call_613806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613806.url(scheme.get, call_613806.host, call_613806.base,
                         call_613806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613806, url, valid)

proc call*(call_613807: Call_GetSnapshotLimits_613794; body: JsonNode): Recallable =
  ## getSnapshotLimits
  ## Obtains the manual snapshot limits for a directory.
  ##   body: JObject (required)
  var body_613808 = newJObject()
  if body != nil:
    body_613808 = body
  result = call_613807.call(nil, nil, nil, nil, body_613808)

var getSnapshotLimits* = Call_GetSnapshotLimits_613794(name: "getSnapshotLimits",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetSnapshotLimits",
    validator: validate_GetSnapshotLimits_613795, base: "/",
    url: url_GetSnapshotLimits_613796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificates_613809 = ref object of OpenApiRestCall_612658
proc url_ListCertificates_613811(protocol: Scheme; host: string; base: string;
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

proc validate_ListCertificates_613810(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
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
  var valid_613812 = header.getOrDefault("X-Amz-Target")
  valid_613812 = validateParameter(valid_613812, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListCertificates"))
  if valid_613812 != nil:
    section.add "X-Amz-Target", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Signature")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Signature", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Content-Sha256", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Date")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Date", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Credential")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Credential", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Security-Token")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Security-Token", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Algorithm")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Algorithm", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-SignedHeaders", valid_613819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613821: Call_ListCertificates_613809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
  ## 
  let valid = call_613821.validator(path, query, header, formData, body)
  let scheme = call_613821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613821.url(scheme.get, call_613821.host, call_613821.base,
                         call_613821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613821, url, valid)

proc call*(call_613822: Call_ListCertificates_613809; body: JsonNode): Recallable =
  ## listCertificates
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_613823 = newJObject()
  if body != nil:
    body_613823 = body
  result = call_613822.call(nil, nil, nil, nil, body_613823)

var listCertificates* = Call_ListCertificates_613809(name: "listCertificates",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListCertificates",
    validator: validate_ListCertificates_613810, base: "/",
    url: url_ListCertificates_613811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIpRoutes_613824 = ref object of OpenApiRestCall_612658
proc url_ListIpRoutes_613826(protocol: Scheme; host: string; base: string;
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

proc validate_ListIpRoutes_613825(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the address blocks that you have added to a directory.
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
  var valid_613827 = header.getOrDefault("X-Amz-Target")
  valid_613827 = validateParameter(valid_613827, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListIpRoutes"))
  if valid_613827 != nil:
    section.add "X-Amz-Target", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Signature")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Signature", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Content-Sha256", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Date")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Date", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Credential")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Credential", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Security-Token")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Security-Token", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Algorithm")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Algorithm", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-SignedHeaders", valid_613834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613836: Call_ListIpRoutes_613824; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the address blocks that you have added to a directory.
  ## 
  let valid = call_613836.validator(path, query, header, formData, body)
  let scheme = call_613836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613836.url(scheme.get, call_613836.host, call_613836.base,
                         call_613836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613836, url, valid)

proc call*(call_613837: Call_ListIpRoutes_613824; body: JsonNode): Recallable =
  ## listIpRoutes
  ## Lists the address blocks that you have added to a directory.
  ##   body: JObject (required)
  var body_613838 = newJObject()
  if body != nil:
    body_613838 = body
  result = call_613837.call(nil, nil, nil, nil, body_613838)

var listIpRoutes* = Call_ListIpRoutes_613824(name: "listIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListIpRoutes",
    validator: validate_ListIpRoutes_613825, base: "/", url: url_ListIpRoutes_613826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogSubscriptions_613839 = ref object of OpenApiRestCall_612658
proc url_ListLogSubscriptions_613841(protocol: Scheme; host: string; base: string;
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

proc validate_ListLogSubscriptions_613840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the active log subscriptions for the AWS account.
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
  var valid_613842 = header.getOrDefault("X-Amz-Target")
  valid_613842 = validateParameter(valid_613842, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListLogSubscriptions"))
  if valid_613842 != nil:
    section.add "X-Amz-Target", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Signature")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Signature", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Content-Sha256", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Date")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Date", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Credential")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Credential", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Security-Token")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Security-Token", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Algorithm")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Algorithm", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-SignedHeaders", valid_613849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613851: Call_ListLogSubscriptions_613839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the active log subscriptions for the AWS account.
  ## 
  let valid = call_613851.validator(path, query, header, formData, body)
  let scheme = call_613851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613851.url(scheme.get, call_613851.host, call_613851.base,
                         call_613851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613851, url, valid)

proc call*(call_613852: Call_ListLogSubscriptions_613839; body: JsonNode): Recallable =
  ## listLogSubscriptions
  ## Lists the active log subscriptions for the AWS account.
  ##   body: JObject (required)
  var body_613853 = newJObject()
  if body != nil:
    body_613853 = body
  result = call_613852.call(nil, nil, nil, nil, body_613853)

var listLogSubscriptions* = Call_ListLogSubscriptions_613839(
    name: "listLogSubscriptions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListLogSubscriptions",
    validator: validate_ListLogSubscriptions_613840, base: "/",
    url: url_ListLogSubscriptions_613841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaExtensions_613854 = ref object of OpenApiRestCall_612658
proc url_ListSchemaExtensions_613856(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemaExtensions_613855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all schema extensions applied to a Microsoft AD Directory.
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
  var valid_613857 = header.getOrDefault("X-Amz-Target")
  valid_613857 = validateParameter(valid_613857, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListSchemaExtensions"))
  if valid_613857 != nil:
    section.add "X-Amz-Target", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Signature")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Signature", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Content-Sha256", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Date")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Date", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Credential")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Credential", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Security-Token")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Security-Token", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Algorithm")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Algorithm", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-SignedHeaders", valid_613864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613866: Call_ListSchemaExtensions_613854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ## 
  let valid = call_613866.validator(path, query, header, formData, body)
  let scheme = call_613866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613866.url(scheme.get, call_613866.host, call_613866.base,
                         call_613866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613866, url, valid)

proc call*(call_613867: Call_ListSchemaExtensions_613854; body: JsonNode): Recallable =
  ## listSchemaExtensions
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ##   body: JObject (required)
  var body_613868 = newJObject()
  if body != nil:
    body_613868 = body
  result = call_613867.call(nil, nil, nil, nil, body_613868)

var listSchemaExtensions* = Call_ListSchemaExtensions_613854(
    name: "listSchemaExtensions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListSchemaExtensions",
    validator: validate_ListSchemaExtensions_613855, base: "/",
    url: url_ListSchemaExtensions_613856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613869 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613871(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613870(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags on a directory.
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
  var valid_613872 = header.getOrDefault("X-Amz-Target")
  valid_613872 = validateParameter(valid_613872, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListTagsForResource"))
  if valid_613872 != nil:
    section.add "X-Amz-Target", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Signature")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Signature", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Content-Sha256", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Date")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Date", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Credential")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Credential", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Security-Token")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Security-Token", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Algorithm")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Algorithm", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-SignedHeaders", valid_613879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613881: Call_ListTagsForResource_613869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a directory.
  ## 
  let valid = call_613881.validator(path, query, header, formData, body)
  let scheme = call_613881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613881.url(scheme.get, call_613881.host, call_613881.base,
                         call_613881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613881, url, valid)

proc call*(call_613882: Call_ListTagsForResource_613869; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags on a directory.
  ##   body: JObject (required)
  var body_613883 = newJObject()
  if body != nil:
    body_613883 = body
  result = call_613882.call(nil, nil, nil, nil, body_613883)

var listTagsForResource* = Call_ListTagsForResource_613869(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListTagsForResource",
    validator: validate_ListTagsForResource_613870, base: "/",
    url: url_ListTagsForResource_613871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCertificate_613884 = ref object of OpenApiRestCall_612658
proc url_RegisterCertificate_613886(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterCertificate_613885(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Registers a certificate for secured LDAP connection.
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
  var valid_613887 = header.getOrDefault("X-Amz-Target")
  valid_613887 = validateParameter(valid_613887, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterCertificate"))
  if valid_613887 != nil:
    section.add "X-Amz-Target", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Signature")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Signature", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Content-Sha256", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Date")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Date", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Credential")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Credential", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Security-Token")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Security-Token", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Algorithm")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Algorithm", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-SignedHeaders", valid_613894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613896: Call_RegisterCertificate_613884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a certificate for secured LDAP connection.
  ## 
  let valid = call_613896.validator(path, query, header, formData, body)
  let scheme = call_613896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613896.url(scheme.get, call_613896.host, call_613896.base,
                         call_613896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613896, url, valid)

proc call*(call_613897: Call_RegisterCertificate_613884; body: JsonNode): Recallable =
  ## registerCertificate
  ## Registers a certificate for secured LDAP connection.
  ##   body: JObject (required)
  var body_613898 = newJObject()
  if body != nil:
    body_613898 = body
  result = call_613897.call(nil, nil, nil, nil, body_613898)

var registerCertificate* = Call_RegisterCertificate_613884(
    name: "registerCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterCertificate",
    validator: validate_RegisterCertificate_613885, base: "/",
    url: url_RegisterCertificate_613886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterEventTopic_613899 = ref object of OpenApiRestCall_612658
proc url_RegisterEventTopic_613901(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterEventTopic_613900(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
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
  var valid_613902 = header.getOrDefault("X-Amz-Target")
  valid_613902 = validateParameter(valid_613902, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterEventTopic"))
  if valid_613902 != nil:
    section.add "X-Amz-Target", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Signature")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Signature", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Content-Sha256", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-Date")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-Date", valid_613905
  var valid_613906 = header.getOrDefault("X-Amz-Credential")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-Credential", valid_613906
  var valid_613907 = header.getOrDefault("X-Amz-Security-Token")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "X-Amz-Security-Token", valid_613907
  var valid_613908 = header.getOrDefault("X-Amz-Algorithm")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Algorithm", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-SignedHeaders", valid_613909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613911: Call_RegisterEventTopic_613899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ## 
  let valid = call_613911.validator(path, query, header, formData, body)
  let scheme = call_613911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613911.url(scheme.get, call_613911.host, call_613911.base,
                         call_613911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613911, url, valid)

proc call*(call_613912: Call_RegisterEventTopic_613899; body: JsonNode): Recallable =
  ## registerEventTopic
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ##   body: JObject (required)
  var body_613913 = newJObject()
  if body != nil:
    body_613913 = body
  result = call_613912.call(nil, nil, nil, nil, body_613913)

var registerEventTopic* = Call_RegisterEventTopic_613899(
    name: "registerEventTopic", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterEventTopic",
    validator: validate_RegisterEventTopic_613900, base: "/",
    url: url_RegisterEventTopic_613901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSharedDirectory_613914 = ref object of OpenApiRestCall_612658
proc url_RejectSharedDirectory_613916(protocol: Scheme; host: string; base: string;
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

proc validate_RejectSharedDirectory_613915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rejects a directory sharing request that was sent from the directory owner account.
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
  var valid_613917 = header.getOrDefault("X-Amz-Target")
  valid_613917 = validateParameter(valid_613917, JString, required = true, default = newJString(
      "DirectoryService_20150416.RejectSharedDirectory"))
  if valid_613917 != nil:
    section.add "X-Amz-Target", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Signature")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Signature", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Content-Sha256", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Date")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Date", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Credential")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Credential", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-Security-Token")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Security-Token", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-Algorithm")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Algorithm", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-SignedHeaders", valid_613924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613926: Call_RejectSharedDirectory_613914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_613926.validator(path, query, header, formData, body)
  let scheme = call_613926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613926.url(scheme.get, call_613926.host, call_613926.base,
                         call_613926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613926, url, valid)

proc call*(call_613927: Call_RejectSharedDirectory_613914; body: JsonNode): Recallable =
  ## rejectSharedDirectory
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_613928 = newJObject()
  if body != nil:
    body_613928 = body
  result = call_613927.call(nil, nil, nil, nil, body_613928)

var rejectSharedDirectory* = Call_RejectSharedDirectory_613914(
    name: "rejectSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RejectSharedDirectory",
    validator: validate_RejectSharedDirectory_613915, base: "/",
    url: url_RejectSharedDirectory_613916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveIpRoutes_613929 = ref object of OpenApiRestCall_612658
proc url_RemoveIpRoutes_613931(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveIpRoutes_613930(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Removes IP address blocks from a directory.
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
  var valid_613932 = header.getOrDefault("X-Amz-Target")
  valid_613932 = validateParameter(valid_613932, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveIpRoutes"))
  if valid_613932 != nil:
    section.add "X-Amz-Target", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Signature")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Signature", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Content-Sha256", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Date")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Date", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Credential")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Credential", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Security-Token")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Security-Token", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Algorithm")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Algorithm", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-SignedHeaders", valid_613939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613941: Call_RemoveIpRoutes_613929; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes IP address blocks from a directory.
  ## 
  let valid = call_613941.validator(path, query, header, formData, body)
  let scheme = call_613941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613941.url(scheme.get, call_613941.host, call_613941.base,
                         call_613941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613941, url, valid)

proc call*(call_613942: Call_RemoveIpRoutes_613929; body: JsonNode): Recallable =
  ## removeIpRoutes
  ## Removes IP address blocks from a directory.
  ##   body: JObject (required)
  var body_613943 = newJObject()
  if body != nil:
    body_613943 = body
  result = call_613942.call(nil, nil, nil, nil, body_613943)

var removeIpRoutes* = Call_RemoveIpRoutes_613929(name: "removeIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveIpRoutes",
    validator: validate_RemoveIpRoutes_613930, base: "/", url: url_RemoveIpRoutes_613931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_613944 = ref object of OpenApiRestCall_612658
proc url_RemoveTagsFromResource_613946(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveTagsFromResource_613945(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a directory.
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
  var valid_613947 = header.getOrDefault("X-Amz-Target")
  valid_613947 = validateParameter(valid_613947, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveTagsFromResource"))
  if valid_613947 != nil:
    section.add "X-Amz-Target", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Signature")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Signature", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Content-Sha256", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-Date")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Date", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Credential")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Credential", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Security-Token")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Security-Token", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Algorithm")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Algorithm", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-SignedHeaders", valid_613954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613956: Call_RemoveTagsFromResource_613944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a directory.
  ## 
  let valid = call_613956.validator(path, query, header, formData, body)
  let scheme = call_613956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613956.url(scheme.get, call_613956.host, call_613956.base,
                         call_613956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613956, url, valid)

proc call*(call_613957: Call_RemoveTagsFromResource_613944; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tags from a directory.
  ##   body: JObject (required)
  var body_613958 = newJObject()
  if body != nil:
    body_613958 = body
  result = call_613957.call(nil, nil, nil, nil, body_613958)

var removeTagsFromResource* = Call_RemoveTagsFromResource_613944(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_613945, base: "/",
    url: url_RemoveTagsFromResource_613946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetUserPassword_613959 = ref object of OpenApiRestCall_612658
proc url_ResetUserPassword_613961(protocol: Scheme; host: string; base: string;
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

proc validate_ResetUserPassword_613960(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
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
  var valid_613962 = header.getOrDefault("X-Amz-Target")
  valid_613962 = validateParameter(valid_613962, JString, required = true, default = newJString(
      "DirectoryService_20150416.ResetUserPassword"))
  if valid_613962 != nil:
    section.add "X-Amz-Target", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Signature")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Signature", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Content-Sha256", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-Date")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Date", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Credential")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Credential", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Security-Token")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Security-Token", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Algorithm")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Algorithm", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-SignedHeaders", valid_613969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613971: Call_ResetUserPassword_613959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_613971.validator(path, query, header, formData, body)
  let scheme = call_613971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613971.url(scheme.get, call_613971.host, call_613971.base,
                         call_613971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613971, url, valid)

proc call*(call_613972: Call_ResetUserPassword_613959; body: JsonNode): Recallable =
  ## resetUserPassword
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613973 = newJObject()
  if body != nil:
    body_613973 = body
  result = call_613972.call(nil, nil, nil, nil, body_613973)

var resetUserPassword* = Call_ResetUserPassword_613959(name: "resetUserPassword",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ResetUserPassword",
    validator: validate_ResetUserPassword_613960, base: "/",
    url: url_ResetUserPassword_613961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreFromSnapshot_613974 = ref object of OpenApiRestCall_612658
proc url_RestoreFromSnapshot_613976(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreFromSnapshot_613975(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
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
  var valid_613977 = header.getOrDefault("X-Amz-Target")
  valid_613977 = validateParameter(valid_613977, JString, required = true, default = newJString(
      "DirectoryService_20150416.RestoreFromSnapshot"))
  if valid_613977 != nil:
    section.add "X-Amz-Target", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Signature")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Signature", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Content-Sha256", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Date")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Date", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Credential")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Credential", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Security-Token")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Security-Token", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Algorithm")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Algorithm", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-SignedHeaders", valid_613984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613986: Call_RestoreFromSnapshot_613974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ## 
  let valid = call_613986.validator(path, query, header, formData, body)
  let scheme = call_613986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613986.url(scheme.get, call_613986.host, call_613986.base,
                         call_613986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613986, url, valid)

proc call*(call_613987: Call_RestoreFromSnapshot_613974; body: JsonNode): Recallable =
  ## restoreFromSnapshot
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ##   body: JObject (required)
  var body_613988 = newJObject()
  if body != nil:
    body_613988 = body
  result = call_613987.call(nil, nil, nil, nil, body_613988)

var restoreFromSnapshot* = Call_RestoreFromSnapshot_613974(
    name: "restoreFromSnapshot", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RestoreFromSnapshot",
    validator: validate_RestoreFromSnapshot_613975, base: "/",
    url: url_RestoreFromSnapshot_613976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShareDirectory_613989 = ref object of OpenApiRestCall_612658
proc url_ShareDirectory_613991(protocol: Scheme; host: string; base: string;
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

proc validate_ShareDirectory_613990(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
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
  var valid_613992 = header.getOrDefault("X-Amz-Target")
  valid_613992 = validateParameter(valid_613992, JString, required = true, default = newJString(
      "DirectoryService_20150416.ShareDirectory"))
  if valid_613992 != nil:
    section.add "X-Amz-Target", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Signature")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Signature", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Content-Sha256", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Date")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Date", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Credential")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Credential", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Security-Token")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Security-Token", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Algorithm")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Algorithm", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-SignedHeaders", valid_613999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614001: Call_ShareDirectory_613989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ## 
  let valid = call_614001.validator(path, query, header, formData, body)
  let scheme = call_614001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614001.url(scheme.get, call_614001.host, call_614001.base,
                         call_614001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614001, url, valid)

proc call*(call_614002: Call_ShareDirectory_613989; body: JsonNode): Recallable =
  ## shareDirectory
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ##   body: JObject (required)
  var body_614003 = newJObject()
  if body != nil:
    body_614003 = body
  result = call_614002.call(nil, nil, nil, nil, body_614003)

var shareDirectory* = Call_ShareDirectory_613989(name: "shareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ShareDirectory",
    validator: validate_ShareDirectory_613990, base: "/", url: url_ShareDirectory_613991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaExtension_614004 = ref object of OpenApiRestCall_612658
proc url_StartSchemaExtension_614006(protocol: Scheme; host: string; base: string;
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

proc validate_StartSchemaExtension_614005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a schema extension to a Microsoft AD directory.
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
  var valid_614007 = header.getOrDefault("X-Amz-Target")
  valid_614007 = validateParameter(valid_614007, JString, required = true, default = newJString(
      "DirectoryService_20150416.StartSchemaExtension"))
  if valid_614007 != nil:
    section.add "X-Amz-Target", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Signature")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Signature", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Content-Sha256", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Date")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Date", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Credential")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Credential", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Security-Token")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Security-Token", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Algorithm")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Algorithm", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-SignedHeaders", valid_614014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614016: Call_StartSchemaExtension_614004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a schema extension to a Microsoft AD directory.
  ## 
  let valid = call_614016.validator(path, query, header, formData, body)
  let scheme = call_614016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614016.url(scheme.get, call_614016.host, call_614016.base,
                         call_614016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614016, url, valid)

proc call*(call_614017: Call_StartSchemaExtension_614004; body: JsonNode): Recallable =
  ## startSchemaExtension
  ## Applies a schema extension to a Microsoft AD directory.
  ##   body: JObject (required)
  var body_614018 = newJObject()
  if body != nil:
    body_614018 = body
  result = call_614017.call(nil, nil, nil, nil, body_614018)

var startSchemaExtension* = Call_StartSchemaExtension_614004(
    name: "startSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.StartSchemaExtension",
    validator: validate_StartSchemaExtension_614005, base: "/",
    url: url_StartSchemaExtension_614006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnshareDirectory_614019 = ref object of OpenApiRestCall_612658
proc url_UnshareDirectory_614021(protocol: Scheme; host: string; base: string;
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

proc validate_UnshareDirectory_614020(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Stops the directory sharing between the directory owner and consumer accounts. 
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
  var valid_614022 = header.getOrDefault("X-Amz-Target")
  valid_614022 = validateParameter(valid_614022, JString, required = true, default = newJString(
      "DirectoryService_20150416.UnshareDirectory"))
  if valid_614022 != nil:
    section.add "X-Amz-Target", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Signature")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Signature", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Content-Sha256", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Date")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Date", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Credential")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Credential", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Security-Token")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Security-Token", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Algorithm")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Algorithm", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-SignedHeaders", valid_614029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614031: Call_UnshareDirectory_614019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ## 
  let valid = call_614031.validator(path, query, header, formData, body)
  let scheme = call_614031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614031.url(scheme.get, call_614031.host, call_614031.base,
                         call_614031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614031, url, valid)

proc call*(call_614032: Call_UnshareDirectory_614019; body: JsonNode): Recallable =
  ## unshareDirectory
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ##   body: JObject (required)
  var body_614033 = newJObject()
  if body != nil:
    body_614033 = body
  result = call_614032.call(nil, nil, nil, nil, body_614033)

var unshareDirectory* = Call_UnshareDirectory_614019(name: "unshareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UnshareDirectory",
    validator: validate_UnshareDirectory_614020, base: "/",
    url: url_UnshareDirectory_614021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConditionalForwarder_614034 = ref object of OpenApiRestCall_612658
proc url_UpdateConditionalForwarder_614036(protocol: Scheme; host: string;
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

proc validate_UpdateConditionalForwarder_614035(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a conditional forwarder that has been set up for your AWS directory.
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
  var valid_614037 = header.getOrDefault("X-Amz-Target")
  valid_614037 = validateParameter(valid_614037, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateConditionalForwarder"))
  if valid_614037 != nil:
    section.add "X-Amz-Target", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-Signature")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Signature", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Content-Sha256", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Date")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Date", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Credential")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Credential", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Security-Token")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Security-Token", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Algorithm")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Algorithm", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-SignedHeaders", valid_614044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614046: Call_UpdateConditionalForwarder_614034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_614046.validator(path, query, header, formData, body)
  let scheme = call_614046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614046.url(scheme.get, call_614046.host, call_614046.base,
                         call_614046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614046, url, valid)

proc call*(call_614047: Call_UpdateConditionalForwarder_614034; body: JsonNode): Recallable =
  ## updateConditionalForwarder
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_614048 = newJObject()
  if body != nil:
    body_614048 = body
  result = call_614047.call(nil, nil, nil, nil, body_614048)

var updateConditionalForwarder* = Call_UpdateConditionalForwarder_614034(
    name: "updateConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateConditionalForwarder",
    validator: validate_UpdateConditionalForwarder_614035, base: "/",
    url: url_UpdateConditionalForwarder_614036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNumberOfDomainControllers_614049 = ref object of OpenApiRestCall_612658
proc url_UpdateNumberOfDomainControllers_614051(protocol: Scheme; host: string;
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

proc validate_UpdateNumberOfDomainControllers_614050(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
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
  var valid_614052 = header.getOrDefault("X-Amz-Target")
  valid_614052 = validateParameter(valid_614052, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateNumberOfDomainControllers"))
  if valid_614052 != nil:
    section.add "X-Amz-Target", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Signature")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Signature", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Content-Sha256", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Date")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Date", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Credential")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Credential", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Security-Token")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Security-Token", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Algorithm")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Algorithm", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-SignedHeaders", valid_614059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614061: Call_UpdateNumberOfDomainControllers_614049;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ## 
  let valid = call_614061.validator(path, query, header, formData, body)
  let scheme = call_614061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614061.url(scheme.get, call_614061.host, call_614061.base,
                         call_614061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614061, url, valid)

proc call*(call_614062: Call_UpdateNumberOfDomainControllers_614049; body: JsonNode): Recallable =
  ## updateNumberOfDomainControllers
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ##   body: JObject (required)
  var body_614063 = newJObject()
  if body != nil:
    body_614063 = body
  result = call_614062.call(nil, nil, nil, nil, body_614063)

var updateNumberOfDomainControllers* = Call_UpdateNumberOfDomainControllers_614049(
    name: "updateNumberOfDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateNumberOfDomainControllers",
    validator: validate_UpdateNumberOfDomainControllers_614050, base: "/",
    url: url_UpdateNumberOfDomainControllers_614051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRadius_614064 = ref object of OpenApiRestCall_612658
proc url_UpdateRadius_614066(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRadius_614065(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
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
  var valid_614067 = header.getOrDefault("X-Amz-Target")
  valid_614067 = validateParameter(valid_614067, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateRadius"))
  if valid_614067 != nil:
    section.add "X-Amz-Target", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Signature")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Signature", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Content-Sha256", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Date")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Date", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Credential")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Credential", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-Security-Token")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-Security-Token", valid_614072
  var valid_614073 = header.getOrDefault("X-Amz-Algorithm")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-Algorithm", valid_614073
  var valid_614074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-SignedHeaders", valid_614074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614076: Call_UpdateRadius_614064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_614076.validator(path, query, header, formData, body)
  let scheme = call_614076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614076.url(scheme.get, call_614076.host, call_614076.base,
                         call_614076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614076, url, valid)

proc call*(call_614077: Call_UpdateRadius_614064; body: JsonNode): Recallable =
  ## updateRadius
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_614078 = newJObject()
  if body != nil:
    body_614078 = body
  result = call_614077.call(nil, nil, nil, nil, body_614078)

var updateRadius* = Call_UpdateRadius_614064(name: "updateRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UpdateRadius",
    validator: validate_UpdateRadius_614065, base: "/", url: url_UpdateRadius_614066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrust_614079 = ref object of OpenApiRestCall_612658
proc url_UpdateTrust_614081(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrust_614080(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
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
  var valid_614082 = header.getOrDefault("X-Amz-Target")
  valid_614082 = validateParameter(valid_614082, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateTrust"))
  if valid_614082 != nil:
    section.add "X-Amz-Target", valid_614082
  var valid_614083 = header.getOrDefault("X-Amz-Signature")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Signature", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Content-Sha256", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-Date")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-Date", valid_614085
  var valid_614086 = header.getOrDefault("X-Amz-Credential")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "X-Amz-Credential", valid_614086
  var valid_614087 = header.getOrDefault("X-Amz-Security-Token")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Security-Token", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Algorithm")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Algorithm", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-SignedHeaders", valid_614089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614091: Call_UpdateTrust_614079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ## 
  let valid = call_614091.validator(path, query, header, formData, body)
  let scheme = call_614091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614091.url(scheme.get, call_614091.host, call_614091.base,
                         call_614091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614091, url, valid)

proc call*(call_614092: Call_UpdateTrust_614079; body: JsonNode): Recallable =
  ## updateTrust
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ##   body: JObject (required)
  var body_614093 = newJObject()
  if body != nil:
    body_614093 = body
  result = call_614092.call(nil, nil, nil, nil, body_614093)

var updateTrust* = Call_UpdateTrust_614079(name: "updateTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateTrust",
                                        validator: validate_UpdateTrust_614080,
                                        base: "/", url: url_UpdateTrust_614081,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyTrust_614094 = ref object of OpenApiRestCall_612658
proc url_VerifyTrust_614096(protocol: Scheme; host: string; base: string;
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

proc validate_VerifyTrust_614095(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
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
  var valid_614097 = header.getOrDefault("X-Amz-Target")
  valid_614097 = validateParameter(valid_614097, JString, required = true, default = newJString(
      "DirectoryService_20150416.VerifyTrust"))
  if valid_614097 != nil:
    section.add "X-Amz-Target", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Signature")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Signature", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Content-Sha256", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-Date")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Date", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-Credential")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Credential", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Security-Token")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Security-Token", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Algorithm")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Algorithm", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-SignedHeaders", valid_614104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614106: Call_VerifyTrust_614094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ## 
  let valid = call_614106.validator(path, query, header, formData, body)
  let scheme = call_614106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614106.url(scheme.get, call_614106.host, call_614106.base,
                         call_614106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614106, url, valid)

proc call*(call_614107: Call_VerifyTrust_614094; body: JsonNode): Recallable =
  ## verifyTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ##   body: JObject (required)
  var body_614108 = newJObject()
  if body != nil:
    body_614108 = body
  result = call_614107.call(nil, nil, nil, nil, body_614108)

var verifyTrust* = Call_VerifyTrust_614094(name: "verifyTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.VerifyTrust",
                                        validator: validate_VerifyTrust_614095,
                                        base: "/", url: url_VerifyTrust_614096,
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
