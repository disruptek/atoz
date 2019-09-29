
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptSharedDirectory_593774 = ref object of OpenApiRestCall_593437
proc url_AcceptSharedDirectory_593776(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptSharedDirectory_593775(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "DirectoryService_20150416.AcceptSharedDirectory"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AcceptSharedDirectory_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AcceptSharedDirectory_593774; body: JsonNode): Recallable =
  ## acceptSharedDirectory
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var acceptSharedDirectory* = Call_AcceptSharedDirectory_593774(
    name: "acceptSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AcceptSharedDirectory",
    validator: validate_AcceptSharedDirectory_593775, base: "/",
    url: url_AcceptSharedDirectory_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddIpRoutes_594043 = ref object of OpenApiRestCall_593437
proc url_AddIpRoutes_594045(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddIpRoutes_594044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "DirectoryService_20150416.AddIpRoutes"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_AddIpRoutes_594043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_AddIpRoutes_594043; body: JsonNode): Recallable =
  ## addIpRoutes
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var addIpRoutes* = Call_AddIpRoutes_594043(name: "addIpRoutes",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.AddIpRoutes",
                                        validator: validate_AddIpRoutes_594044,
                                        base: "/", url: url_AddIpRoutes_594045,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_594058 = ref object of OpenApiRestCall_593437
proc url_AddTagsToResource_594060(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToResource_594059(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "DirectoryService_20150416.AddTagsToResource"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_AddTagsToResource_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_AddTagsToResource_594058; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var addTagsToResource* = Call_AddTagsToResource_594058(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AddTagsToResource",
    validator: validate_AddTagsToResource_594059, base: "/",
    url: url_AddTagsToResource_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSchemaExtension_594073 = ref object of OpenApiRestCall_593437
proc url_CancelSchemaExtension_594075(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelSchemaExtension_594074(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "DirectoryService_20150416.CancelSchemaExtension"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CancelSchemaExtension_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CancelSchemaExtension_594073; body: JsonNode): Recallable =
  ## cancelSchemaExtension
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var cancelSchemaExtension* = Call_CancelSchemaExtension_594073(
    name: "cancelSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CancelSchemaExtension",
    validator: validate_CancelSchemaExtension_594074, base: "/",
    url: url_CancelSchemaExtension_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectDirectory_594088 = ref object of OpenApiRestCall_593437
proc url_ConnectDirectory_594090(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ConnectDirectory_594089(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "DirectoryService_20150416.ConnectDirectory"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_ConnectDirectory_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_ConnectDirectory_594088; body: JsonNode): Recallable =
  ## connectDirectory
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var connectDirectory* = Call_ConnectDirectory_594088(name: "connectDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ConnectDirectory",
    validator: validate_ConnectDirectory_594089, base: "/",
    url: url_ConnectDirectory_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_594103 = ref object of OpenApiRestCall_593437
proc url_CreateAlias_594105(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAlias_594104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateAlias"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateAlias_594103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateAlias_594103; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createAlias* = Call_CreateAlias_594103(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateAlias",
                                        validator: validate_CreateAlias_594104,
                                        base: "/", url: url_CreateAlias_594105,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputer_594118 = ref object of OpenApiRestCall_593437
proc url_CreateComputer_594120(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateComputer_594119(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateComputer"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateComputer_594118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateComputer_594118; body: JsonNode): Recallable =
  ## createComputer
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createComputer* = Call_CreateComputer_594118(name: "createComputer",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateComputer",
    validator: validate_CreateComputer_594119, base: "/", url: url_CreateComputer_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConditionalForwarder_594133 = ref object of OpenApiRestCall_593437
proc url_CreateConditionalForwarder_594135(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConditionalForwarder_594134(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateConditionalForwarder"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_CreateConditionalForwarder_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_CreateConditionalForwarder_594133; body: JsonNode): Recallable =
  ## createConditionalForwarder
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var createConditionalForwarder* = Call_CreateConditionalForwarder_594133(
    name: "createConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateConditionalForwarder",
    validator: validate_CreateConditionalForwarder_594134, base: "/",
    url: url_CreateConditionalForwarder_594135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_594148 = ref object of OpenApiRestCall_593437
proc url_CreateDirectory_594150(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDirectory_594149(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a Simple AD directory.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateDirectory"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_CreateDirectory_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Simple AD directory.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_CreateDirectory_594148; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a Simple AD directory.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var createDirectory* = Call_CreateDirectory_594148(name: "createDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateDirectory",
    validator: validate_CreateDirectory_594149, base: "/", url: url_CreateDirectory_594150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogSubscription_594163 = ref object of OpenApiRestCall_593437
proc url_CreateLogSubscription_594165(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLogSubscription_594164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a subscription to forward real time Directory Service domain controller security logs to the specified CloudWatch log group in your AWS account.
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateLogSubscription"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_CreateLogSubscription_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription to forward real time Directory Service domain controller security logs to the specified CloudWatch log group in your AWS account.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_CreateLogSubscription_594163; body: JsonNode): Recallable =
  ## createLogSubscription
  ## Creates a subscription to forward real time Directory Service domain controller security logs to the specified CloudWatch log group in your AWS account.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var createLogSubscription* = Call_CreateLogSubscription_594163(
    name: "createLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateLogSubscription",
    validator: validate_CreateLogSubscription_594164, base: "/",
    url: url_CreateLogSubscription_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMicrosoftAD_594178 = ref object of OpenApiRestCall_593437
proc url_CreateMicrosoftAD_594180(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMicrosoftAD_594179(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an AWS Managed Microsoft AD directory.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateMicrosoftAD"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_CreateMicrosoftAD_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Managed Microsoft AD directory.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_CreateMicrosoftAD_594178; body: JsonNode): Recallable =
  ## createMicrosoftAD
  ## <p>Creates an AWS Managed Microsoft AD directory.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var createMicrosoftAD* = Call_CreateMicrosoftAD_594178(name: "createMicrosoftAD",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateMicrosoftAD",
    validator: validate_CreateMicrosoftAD_594179, base: "/",
    url: url_CreateMicrosoftAD_594180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_594193 = ref object of OpenApiRestCall_593437
proc url_CreateSnapshot_594195(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSnapshot_594194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateSnapshot"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_CreateSnapshot_594193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_CreateSnapshot_594193; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var createSnapshot* = Call_CreateSnapshot_594193(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateSnapshot",
    validator: validate_CreateSnapshot_594194, base: "/", url: url_CreateSnapshot_594195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrust_594208 = ref object of OpenApiRestCall_593437
proc url_CreateTrust_594210(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrust_594209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateTrust"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_CreateTrust_594208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_CreateTrust_594208; body: JsonNode): Recallable =
  ## createTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var createTrust* = Call_CreateTrust_594208(name: "createTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateTrust",
                                        validator: validate_CreateTrust_594209,
                                        base: "/", url: url_CreateTrust_594210,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConditionalForwarder_594223 = ref object of OpenApiRestCall_593437
proc url_DeleteConditionalForwarder_594225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConditionalForwarder_594224(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteConditionalForwarder"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DeleteConditionalForwarder_594223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DeleteConditionalForwarder_594223; body: JsonNode): Recallable =
  ## deleteConditionalForwarder
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var deleteConditionalForwarder* = Call_DeleteConditionalForwarder_594223(
    name: "deleteConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteConditionalForwarder",
    validator: validate_DeleteConditionalForwarder_594224, base: "/",
    url: url_DeleteConditionalForwarder_594225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_594238 = ref object of OpenApiRestCall_593437
proc url_DeleteDirectory_594240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDirectory_594239(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteDirectory"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_DeleteDirectory_594238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_DeleteDirectory_594238; body: JsonNode): Recallable =
  ## deleteDirectory
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var deleteDirectory* = Call_DeleteDirectory_594238(name: "deleteDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteDirectory",
    validator: validate_DeleteDirectory_594239, base: "/", url: url_DeleteDirectory_594240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogSubscription_594253 = ref object of OpenApiRestCall_593437
proc url_DeleteLogSubscription_594255(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLogSubscription_594254(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteLogSubscription"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_DeleteLogSubscription_594253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log subscription.
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_DeleteLogSubscription_594253; body: JsonNode): Recallable =
  ## deleteLogSubscription
  ## Deletes the specified log subscription.
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var deleteLogSubscription* = Call_DeleteLogSubscription_594253(
    name: "deleteLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteLogSubscription",
    validator: validate_DeleteLogSubscription_594254, base: "/",
    url: url_DeleteLogSubscription_594255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshot_594268 = ref object of OpenApiRestCall_593437
proc url_DeleteSnapshot_594270(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSnapshot_594269(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteSnapshot"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_DeleteSnapshot_594268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory snapshot.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_DeleteSnapshot_594268; body: JsonNode): Recallable =
  ## deleteSnapshot
  ## Deletes a directory snapshot.
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var deleteSnapshot* = Call_DeleteSnapshot_594268(name: "deleteSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteSnapshot",
    validator: validate_DeleteSnapshot_594269, base: "/", url: url_DeleteSnapshot_594270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrust_594283 = ref object of OpenApiRestCall_593437
proc url_DeleteTrust_594285(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTrust_594284(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594288 = header.getOrDefault("X-Amz-Target")
  valid_594288 = validateParameter(valid_594288, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteTrust"))
  if valid_594288 != nil:
    section.add "X-Amz-Target", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_DeleteTrust_594283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_DeleteTrust_594283; body: JsonNode): Recallable =
  ## deleteTrust
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ##   body: JObject (required)
  var body_594297 = newJObject()
  if body != nil:
    body_594297 = body
  result = call_594296.call(nil, nil, nil, nil, body_594297)

var deleteTrust* = Call_DeleteTrust_594283(name: "deleteTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteTrust",
                                        validator: validate_DeleteTrust_594284,
                                        base: "/", url: url_DeleteTrust_594285,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterEventTopic_594298 = ref object of OpenApiRestCall_593437
proc url_DeregisterEventTopic_594300(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterEventTopic_594299(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594303 = header.getOrDefault("X-Amz-Target")
  valid_594303 = validateParameter(valid_594303, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterEventTopic"))
  if valid_594303 != nil:
    section.add "X-Amz-Target", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_DeregisterEventTopic_594298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_DeregisterEventTopic_594298; body: JsonNode): Recallable =
  ## deregisterEventTopic
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ##   body: JObject (required)
  var body_594312 = newJObject()
  if body != nil:
    body_594312 = body
  result = call_594311.call(nil, nil, nil, nil, body_594312)

var deregisterEventTopic* = Call_DeregisterEventTopic_594298(
    name: "deregisterEventTopic", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterEventTopic",
    validator: validate_DeregisterEventTopic_594299, base: "/",
    url: url_DeregisterEventTopic_594300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConditionalForwarders_594313 = ref object of OpenApiRestCall_593437
proc url_DescribeConditionalForwarders_594315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConditionalForwarders_594314(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594318 = header.getOrDefault("X-Amz-Target")
  valid_594318 = validateParameter(valid_594318, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeConditionalForwarders"))
  if valid_594318 != nil:
    section.add "X-Amz-Target", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Content-Sha256", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Signature")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Signature", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Credential")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Credential", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_DescribeConditionalForwarders_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_DescribeConditionalForwarders_594313; body: JsonNode): Recallable =
  ## describeConditionalForwarders
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ##   body: JObject (required)
  var body_594327 = newJObject()
  if body != nil:
    body_594327 = body
  result = call_594326.call(nil, nil, nil, nil, body_594327)

var describeConditionalForwarders* = Call_DescribeConditionalForwarders_594313(
    name: "describeConditionalForwarders", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeConditionalForwarders",
    validator: validate_DescribeConditionalForwarders_594314, base: "/",
    url: url_DescribeConditionalForwarders_594315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectories_594328 = ref object of OpenApiRestCall_593437
proc url_DescribeDirectories_594330(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDirectories_594329(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594333 = header.getOrDefault("X-Amz-Target")
  valid_594333 = validateParameter(valid_594333, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDirectories"))
  if valid_594333 != nil:
    section.add "X-Amz-Target", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Credential")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Credential", valid_594338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_DescribeDirectories_594328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_DescribeDirectories_594328; body: JsonNode): Recallable =
  ## describeDirectories
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ##   body: JObject (required)
  var body_594342 = newJObject()
  if body != nil:
    body_594342 = body
  result = call_594341.call(nil, nil, nil, nil, body_594342)

var describeDirectories* = Call_DescribeDirectories_594328(
    name: "describeDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDirectories",
    validator: validate_DescribeDirectories_594329, base: "/",
    url: url_DescribeDirectories_594330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomainControllers_594343 = ref object of OpenApiRestCall_593437
proc url_DescribeDomainControllers_594345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDomainControllers_594344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information about any domain controllers in your directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594346 = query.getOrDefault("Limit")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "Limit", valid_594346
  var valid_594347 = query.getOrDefault("NextToken")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "NextToken", valid_594347
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
  var valid_594348 = header.getOrDefault("X-Amz-Date")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Date", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Security-Token")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Security-Token", valid_594349
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594350 = header.getOrDefault("X-Amz-Target")
  valid_594350 = validateParameter(valid_594350, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDomainControllers"))
  if valid_594350 != nil:
    section.add "X-Amz-Target", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Content-Sha256", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Algorithm")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Algorithm", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Signature")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Signature", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-SignedHeaders", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Credential")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Credential", valid_594355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594357: Call_DescribeDomainControllers_594343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about any domain controllers in your directory.
  ## 
  let valid = call_594357.validator(path, query, header, formData, body)
  let scheme = call_594357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594357.url(scheme.get, call_594357.host, call_594357.base,
                         call_594357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594357, url, valid)

proc call*(call_594358: Call_DescribeDomainControllers_594343; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeDomainControllers
  ## Provides information about any domain controllers in your directory.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594359 = newJObject()
  var body_594360 = newJObject()
  add(query_594359, "Limit", newJString(Limit))
  add(query_594359, "NextToken", newJString(NextToken))
  if body != nil:
    body_594360 = body
  result = call_594358.call(nil, query_594359, nil, nil, body_594360)

var describeDomainControllers* = Call_DescribeDomainControllers_594343(
    name: "describeDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDomainControllers",
    validator: validate_DescribeDomainControllers_594344, base: "/",
    url: url_DescribeDomainControllers_594345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTopics_594362 = ref object of OpenApiRestCall_593437
proc url_DescribeEventTopics_594364(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEventTopics_594363(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594365 = header.getOrDefault("X-Amz-Date")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Date", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Security-Token")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Security-Token", valid_594366
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594367 = header.getOrDefault("X-Amz-Target")
  valid_594367 = validateParameter(valid_594367, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeEventTopics"))
  if valid_594367 != nil:
    section.add "X-Amz-Target", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Content-Sha256", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Algorithm")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Algorithm", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Signature")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Signature", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-SignedHeaders", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Credential")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Credential", valid_594372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594374: Call_DescribeEventTopics_594362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ## 
  let valid = call_594374.validator(path, query, header, formData, body)
  let scheme = call_594374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594374.url(scheme.get, call_594374.host, call_594374.base,
                         call_594374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594374, url, valid)

proc call*(call_594375: Call_DescribeEventTopics_594362; body: JsonNode): Recallable =
  ## describeEventTopics
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ##   body: JObject (required)
  var body_594376 = newJObject()
  if body != nil:
    body_594376 = body
  result = call_594375.call(nil, nil, nil, nil, body_594376)

var describeEventTopics* = Call_DescribeEventTopics_594362(
    name: "describeEventTopics", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeEventTopics",
    validator: validate_DescribeEventTopics_594363, base: "/",
    url: url_DescribeEventTopics_594364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSharedDirectories_594377 = ref object of OpenApiRestCall_593437
proc url_DescribeSharedDirectories_594379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSharedDirectories_594378(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594380 = header.getOrDefault("X-Amz-Date")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Date", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Security-Token")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Security-Token", valid_594381
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594382 = header.getOrDefault("X-Amz-Target")
  valid_594382 = validateParameter(valid_594382, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSharedDirectories"))
  if valid_594382 != nil:
    section.add "X-Amz-Target", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Content-Sha256", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Algorithm")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Algorithm", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Signature")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Signature", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-SignedHeaders", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Credential")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Credential", valid_594387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594389: Call_DescribeSharedDirectories_594377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the shared directories in your account. 
  ## 
  let valid = call_594389.validator(path, query, header, formData, body)
  let scheme = call_594389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594389.url(scheme.get, call_594389.host, call_594389.base,
                         call_594389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594389, url, valid)

proc call*(call_594390: Call_DescribeSharedDirectories_594377; body: JsonNode): Recallable =
  ## describeSharedDirectories
  ## Returns the shared directories in your account. 
  ##   body: JObject (required)
  var body_594391 = newJObject()
  if body != nil:
    body_594391 = body
  result = call_594390.call(nil, nil, nil, nil, body_594391)

var describeSharedDirectories* = Call_DescribeSharedDirectories_594377(
    name: "describeSharedDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSharedDirectories",
    validator: validate_DescribeSharedDirectories_594378, base: "/",
    url: url_DescribeSharedDirectories_594379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshots_594392 = ref object of OpenApiRestCall_593437
proc url_DescribeSnapshots_594394(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSnapshots_594393(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594395 = header.getOrDefault("X-Amz-Date")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Date", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Security-Token")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Security-Token", valid_594396
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594397 = header.getOrDefault("X-Amz-Target")
  valid_594397 = validateParameter(valid_594397, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSnapshots"))
  if valid_594397 != nil:
    section.add "X-Amz-Target", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Content-Sha256", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Algorithm")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Algorithm", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Signature")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Signature", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-SignedHeaders", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Credential")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Credential", valid_594402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594404: Call_DescribeSnapshots_594392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ## 
  let valid = call_594404.validator(path, query, header, formData, body)
  let scheme = call_594404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594404.url(scheme.get, call_594404.host, call_594404.base,
                         call_594404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594404, url, valid)

proc call*(call_594405: Call_DescribeSnapshots_594392; body: JsonNode): Recallable =
  ## describeSnapshots
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ##   body: JObject (required)
  var body_594406 = newJObject()
  if body != nil:
    body_594406 = body
  result = call_594405.call(nil, nil, nil, nil, body_594406)

var describeSnapshots* = Call_DescribeSnapshots_594392(name: "describeSnapshots",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSnapshots",
    validator: validate_DescribeSnapshots_594393, base: "/",
    url: url_DescribeSnapshots_594394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrusts_594407 = ref object of OpenApiRestCall_593437
proc url_DescribeTrusts_594409(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrusts_594408(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594410 = header.getOrDefault("X-Amz-Date")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Date", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Security-Token")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Security-Token", valid_594411
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594412 = header.getOrDefault("X-Amz-Target")
  valid_594412 = validateParameter(valid_594412, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeTrusts"))
  if valid_594412 != nil:
    section.add "X-Amz-Target", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Content-Sha256", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Algorithm")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Algorithm", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Signature")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Signature", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-SignedHeaders", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Credential")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Credential", valid_594417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594419: Call_DescribeTrusts_594407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ## 
  let valid = call_594419.validator(path, query, header, formData, body)
  let scheme = call_594419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594419.url(scheme.get, call_594419.host, call_594419.base,
                         call_594419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594419, url, valid)

proc call*(call_594420: Call_DescribeTrusts_594407; body: JsonNode): Recallable =
  ## describeTrusts
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ##   body: JObject (required)
  var body_594421 = newJObject()
  if body != nil:
    body_594421 = body
  result = call_594420.call(nil, nil, nil, nil, body_594421)

var describeTrusts* = Call_DescribeTrusts_594407(name: "describeTrusts",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeTrusts",
    validator: validate_DescribeTrusts_594408, base: "/", url: url_DescribeTrusts_594409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableRadius_594422 = ref object of OpenApiRestCall_593437
proc url_DisableRadius_594424(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableRadius_594423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Security-Token")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Security-Token", valid_594426
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594427 = header.getOrDefault("X-Amz-Target")
  valid_594427 = validateParameter(valid_594427, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableRadius"))
  if valid_594427 != nil:
    section.add "X-Amz-Target", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Content-Sha256", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Algorithm")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Algorithm", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Signature")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Signature", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-SignedHeaders", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Credential")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Credential", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594434: Call_DisableRadius_594422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_594434.validator(path, query, header, formData, body)
  let scheme = call_594434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594434.url(scheme.get, call_594434.host, call_594434.base,
                         call_594434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594434, url, valid)

proc call*(call_594435: Call_DisableRadius_594422; body: JsonNode): Recallable =
  ## disableRadius
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_594436 = newJObject()
  if body != nil:
    body_594436 = body
  result = call_594435.call(nil, nil, nil, nil, body_594436)

var disableRadius* = Call_DisableRadius_594422(name: "disableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableRadius",
    validator: validate_DisableRadius_594423, base: "/", url: url_DisableRadius_594424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSso_594437 = ref object of OpenApiRestCall_593437
proc url_DisableSso_594439(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableSso_594438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594440 = header.getOrDefault("X-Amz-Date")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Date", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Security-Token")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Security-Token", valid_594441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594442 = header.getOrDefault("X-Amz-Target")
  valid_594442 = validateParameter(valid_594442, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableSso"))
  if valid_594442 != nil:
    section.add "X-Amz-Target", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Content-Sha256", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Algorithm")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Algorithm", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Signature")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Signature", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-SignedHeaders", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Credential")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Credential", valid_594447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594449: Call_DisableSso_594437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables single-sign on for a directory.
  ## 
  let valid = call_594449.validator(path, query, header, formData, body)
  let scheme = call_594449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594449.url(scheme.get, call_594449.host, call_594449.base,
                         call_594449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594449, url, valid)

proc call*(call_594450: Call_DisableSso_594437; body: JsonNode): Recallable =
  ## disableSso
  ## Disables single-sign on for a directory.
  ##   body: JObject (required)
  var body_594451 = newJObject()
  if body != nil:
    body_594451 = body
  result = call_594450.call(nil, nil, nil, nil, body_594451)

var disableSso* = Call_DisableSso_594437(name: "disableSso",
                                      meth: HttpMethod.HttpPost,
                                      host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DisableSso",
                                      validator: validate_DisableSso_594438,
                                      base: "/", url: url_DisableSso_594439,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableRadius_594452 = ref object of OpenApiRestCall_593437
proc url_EnableRadius_594454(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableRadius_594453(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594455 = header.getOrDefault("X-Amz-Date")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Date", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Security-Token")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Security-Token", valid_594456
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594457 = header.getOrDefault("X-Amz-Target")
  valid_594457 = validateParameter(valid_594457, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableRadius"))
  if valid_594457 != nil:
    section.add "X-Amz-Target", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Content-Sha256", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Signature")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Signature", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-SignedHeaders", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Credential")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Credential", valid_594462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594464: Call_EnableRadius_594452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_594464.validator(path, query, header, formData, body)
  let scheme = call_594464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594464.url(scheme.get, call_594464.host, call_594464.base,
                         call_594464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594464, url, valid)

proc call*(call_594465: Call_EnableRadius_594452; body: JsonNode): Recallable =
  ## enableRadius
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_594466 = newJObject()
  if body != nil:
    body_594466 = body
  result = call_594465.call(nil, nil, nil, nil, body_594466)

var enableRadius* = Call_EnableRadius_594452(name: "enableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.EnableRadius",
    validator: validate_EnableRadius_594453, base: "/", url: url_EnableRadius_594454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSso_594467 = ref object of OpenApiRestCall_593437
proc url_EnableSso_594469(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableSso_594468(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables single sign-on for a directory.
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
  var valid_594470 = header.getOrDefault("X-Amz-Date")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Date", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Security-Token")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Security-Token", valid_594471
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594472 = header.getOrDefault("X-Amz-Target")
  valid_594472 = validateParameter(valid_594472, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableSso"))
  if valid_594472 != nil:
    section.add "X-Amz-Target", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Content-Sha256", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Algorithm")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Algorithm", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Signature")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Signature", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-SignedHeaders", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Credential")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Credential", valid_594477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594479: Call_EnableSso_594467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables single sign-on for a directory.
  ## 
  let valid = call_594479.validator(path, query, header, formData, body)
  let scheme = call_594479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594479.url(scheme.get, call_594479.host, call_594479.base,
                         call_594479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594479, url, valid)

proc call*(call_594480: Call_EnableSso_594467; body: JsonNode): Recallable =
  ## enableSso
  ## Enables single sign-on for a directory.
  ##   body: JObject (required)
  var body_594481 = newJObject()
  if body != nil:
    body_594481 = body
  result = call_594480.call(nil, nil, nil, nil, body_594481)

var enableSso* = Call_EnableSso_594467(name: "enableSso", meth: HttpMethod.HttpPost,
                                    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableSso",
                                    validator: validate_EnableSso_594468,
                                    base: "/", url: url_EnableSso_594469,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectoryLimits_594482 = ref object of OpenApiRestCall_593437
proc url_GetDirectoryLimits_594484(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDirectoryLimits_594483(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Obtains directory limit information for the current region.
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
  var valid_594485 = header.getOrDefault("X-Amz-Date")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Date", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Security-Token")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Security-Token", valid_594486
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594487 = header.getOrDefault("X-Amz-Target")
  valid_594487 = validateParameter(valid_594487, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetDirectoryLimits"))
  if valid_594487 != nil:
    section.add "X-Amz-Target", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Content-Sha256", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Algorithm")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Algorithm", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Signature")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Signature", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-SignedHeaders", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Credential")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Credential", valid_594492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594494: Call_GetDirectoryLimits_594482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains directory limit information for the current region.
  ## 
  let valid = call_594494.validator(path, query, header, formData, body)
  let scheme = call_594494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594494.url(scheme.get, call_594494.host, call_594494.base,
                         call_594494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594494, url, valid)

proc call*(call_594495: Call_GetDirectoryLimits_594482; body: JsonNode): Recallable =
  ## getDirectoryLimits
  ## Obtains directory limit information for the current region.
  ##   body: JObject (required)
  var body_594496 = newJObject()
  if body != nil:
    body_594496 = body
  result = call_594495.call(nil, nil, nil, nil, body_594496)

var getDirectoryLimits* = Call_GetDirectoryLimits_594482(
    name: "getDirectoryLimits", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetDirectoryLimits",
    validator: validate_GetDirectoryLimits_594483, base: "/",
    url: url_GetDirectoryLimits_594484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnapshotLimits_594497 = ref object of OpenApiRestCall_593437
proc url_GetSnapshotLimits_594499(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSnapshotLimits_594498(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594500 = header.getOrDefault("X-Amz-Date")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Date", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Security-Token")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Security-Token", valid_594501
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594502 = header.getOrDefault("X-Amz-Target")
  valid_594502 = validateParameter(valid_594502, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetSnapshotLimits"))
  if valid_594502 != nil:
    section.add "X-Amz-Target", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Content-Sha256", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Algorithm")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Algorithm", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Signature")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Signature", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-SignedHeaders", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Credential")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Credential", valid_594507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594509: Call_GetSnapshotLimits_594497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains the manual snapshot limits for a directory.
  ## 
  let valid = call_594509.validator(path, query, header, formData, body)
  let scheme = call_594509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594509.url(scheme.get, call_594509.host, call_594509.base,
                         call_594509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594509, url, valid)

proc call*(call_594510: Call_GetSnapshotLimits_594497; body: JsonNode): Recallable =
  ## getSnapshotLimits
  ## Obtains the manual snapshot limits for a directory.
  ##   body: JObject (required)
  var body_594511 = newJObject()
  if body != nil:
    body_594511 = body
  result = call_594510.call(nil, nil, nil, nil, body_594511)

var getSnapshotLimits* = Call_GetSnapshotLimits_594497(name: "getSnapshotLimits",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetSnapshotLimits",
    validator: validate_GetSnapshotLimits_594498, base: "/",
    url: url_GetSnapshotLimits_594499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIpRoutes_594512 = ref object of OpenApiRestCall_593437
proc url_ListIpRoutes_594514(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListIpRoutes_594513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594515 = header.getOrDefault("X-Amz-Date")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Date", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Security-Token")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Security-Token", valid_594516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594517 = header.getOrDefault("X-Amz-Target")
  valid_594517 = validateParameter(valid_594517, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListIpRoutes"))
  if valid_594517 != nil:
    section.add "X-Amz-Target", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Content-Sha256", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Algorithm")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Algorithm", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Signature")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Signature", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-SignedHeaders", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Credential")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Credential", valid_594522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594524: Call_ListIpRoutes_594512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the address blocks that you have added to a directory.
  ## 
  let valid = call_594524.validator(path, query, header, formData, body)
  let scheme = call_594524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594524.url(scheme.get, call_594524.host, call_594524.base,
                         call_594524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594524, url, valid)

proc call*(call_594525: Call_ListIpRoutes_594512; body: JsonNode): Recallable =
  ## listIpRoutes
  ## Lists the address blocks that you have added to a directory.
  ##   body: JObject (required)
  var body_594526 = newJObject()
  if body != nil:
    body_594526 = body
  result = call_594525.call(nil, nil, nil, nil, body_594526)

var listIpRoutes* = Call_ListIpRoutes_594512(name: "listIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListIpRoutes",
    validator: validate_ListIpRoutes_594513, base: "/", url: url_ListIpRoutes_594514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogSubscriptions_594527 = ref object of OpenApiRestCall_593437
proc url_ListLogSubscriptions_594529(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLogSubscriptions_594528(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594530 = header.getOrDefault("X-Amz-Date")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Date", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Security-Token")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Security-Token", valid_594531
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594532 = header.getOrDefault("X-Amz-Target")
  valid_594532 = validateParameter(valid_594532, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListLogSubscriptions"))
  if valid_594532 != nil:
    section.add "X-Amz-Target", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Content-Sha256", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Algorithm")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Algorithm", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Signature")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Signature", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-SignedHeaders", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Credential")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Credential", valid_594537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_ListLogSubscriptions_594527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the active log subscriptions for the AWS account.
  ## 
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_ListLogSubscriptions_594527; body: JsonNode): Recallable =
  ## listLogSubscriptions
  ## Lists the active log subscriptions for the AWS account.
  ##   body: JObject (required)
  var body_594541 = newJObject()
  if body != nil:
    body_594541 = body
  result = call_594540.call(nil, nil, nil, nil, body_594541)

var listLogSubscriptions* = Call_ListLogSubscriptions_594527(
    name: "listLogSubscriptions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListLogSubscriptions",
    validator: validate_ListLogSubscriptions_594528, base: "/",
    url: url_ListLogSubscriptions_594529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaExtensions_594542 = ref object of OpenApiRestCall_593437
proc url_ListSchemaExtensions_594544(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSchemaExtensions_594543(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594545 = header.getOrDefault("X-Amz-Date")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Date", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Security-Token")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Security-Token", valid_594546
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594547 = header.getOrDefault("X-Amz-Target")
  valid_594547 = validateParameter(valid_594547, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListSchemaExtensions"))
  if valid_594547 != nil:
    section.add "X-Amz-Target", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Content-Sha256", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Algorithm")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Algorithm", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Signature")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Signature", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-SignedHeaders", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Credential")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Credential", valid_594552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594554: Call_ListSchemaExtensions_594542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ## 
  let valid = call_594554.validator(path, query, header, formData, body)
  let scheme = call_594554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594554.url(scheme.get, call_594554.host, call_594554.base,
                         call_594554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594554, url, valid)

proc call*(call_594555: Call_ListSchemaExtensions_594542; body: JsonNode): Recallable =
  ## listSchemaExtensions
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ##   body: JObject (required)
  var body_594556 = newJObject()
  if body != nil:
    body_594556 = body
  result = call_594555.call(nil, nil, nil, nil, body_594556)

var listSchemaExtensions* = Call_ListSchemaExtensions_594542(
    name: "listSchemaExtensions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListSchemaExtensions",
    validator: validate_ListSchemaExtensions_594543, base: "/",
    url: url_ListSchemaExtensions_594544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594557 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594559(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594558(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594560 = header.getOrDefault("X-Amz-Date")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Date", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Security-Token")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Security-Token", valid_594561
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594562 = header.getOrDefault("X-Amz-Target")
  valid_594562 = validateParameter(valid_594562, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListTagsForResource"))
  if valid_594562 != nil:
    section.add "X-Amz-Target", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Content-Sha256", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Algorithm")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Algorithm", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Signature")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Signature", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-SignedHeaders", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Credential")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Credential", valid_594567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594569: Call_ListTagsForResource_594557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a directory.
  ## 
  let valid = call_594569.validator(path, query, header, formData, body)
  let scheme = call_594569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594569.url(scheme.get, call_594569.host, call_594569.base,
                         call_594569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594569, url, valid)

proc call*(call_594570: Call_ListTagsForResource_594557; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags on a directory.
  ##   body: JObject (required)
  var body_594571 = newJObject()
  if body != nil:
    body_594571 = body
  result = call_594570.call(nil, nil, nil, nil, body_594571)

var listTagsForResource* = Call_ListTagsForResource_594557(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListTagsForResource",
    validator: validate_ListTagsForResource_594558, base: "/",
    url: url_ListTagsForResource_594559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterEventTopic_594572 = ref object of OpenApiRestCall_593437
proc url_RegisterEventTopic_594574(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterEventTopic_594573(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594575 = header.getOrDefault("X-Amz-Date")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Date", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Security-Token")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Security-Token", valid_594576
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594577 = header.getOrDefault("X-Amz-Target")
  valid_594577 = validateParameter(valid_594577, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterEventTopic"))
  if valid_594577 != nil:
    section.add "X-Amz-Target", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Content-Sha256", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Algorithm")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Algorithm", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Signature")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Signature", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-SignedHeaders", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Credential")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Credential", valid_594582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594584: Call_RegisterEventTopic_594572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ## 
  let valid = call_594584.validator(path, query, header, formData, body)
  let scheme = call_594584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594584.url(scheme.get, call_594584.host, call_594584.base,
                         call_594584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594584, url, valid)

proc call*(call_594585: Call_RegisterEventTopic_594572; body: JsonNode): Recallable =
  ## registerEventTopic
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ##   body: JObject (required)
  var body_594586 = newJObject()
  if body != nil:
    body_594586 = body
  result = call_594585.call(nil, nil, nil, nil, body_594586)

var registerEventTopic* = Call_RegisterEventTopic_594572(
    name: "registerEventTopic", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterEventTopic",
    validator: validate_RegisterEventTopic_594573, base: "/",
    url: url_RegisterEventTopic_594574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSharedDirectory_594587 = ref object of OpenApiRestCall_593437
proc url_RejectSharedDirectory_594589(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectSharedDirectory_594588(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594590 = header.getOrDefault("X-Amz-Date")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Date", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Security-Token")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Security-Token", valid_594591
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594592 = header.getOrDefault("X-Amz-Target")
  valid_594592 = validateParameter(valid_594592, JString, required = true, default = newJString(
      "DirectoryService_20150416.RejectSharedDirectory"))
  if valid_594592 != nil:
    section.add "X-Amz-Target", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Content-Sha256", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Algorithm")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Algorithm", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Signature")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Signature", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-SignedHeaders", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Credential")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Credential", valid_594597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594599: Call_RejectSharedDirectory_594587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_594599.validator(path, query, header, formData, body)
  let scheme = call_594599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594599.url(scheme.get, call_594599.host, call_594599.base,
                         call_594599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594599, url, valid)

proc call*(call_594600: Call_RejectSharedDirectory_594587; body: JsonNode): Recallable =
  ## rejectSharedDirectory
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_594601 = newJObject()
  if body != nil:
    body_594601 = body
  result = call_594600.call(nil, nil, nil, nil, body_594601)

var rejectSharedDirectory* = Call_RejectSharedDirectory_594587(
    name: "rejectSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RejectSharedDirectory",
    validator: validate_RejectSharedDirectory_594588, base: "/",
    url: url_RejectSharedDirectory_594589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveIpRoutes_594602 = ref object of OpenApiRestCall_593437
proc url_RemoveIpRoutes_594604(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveIpRoutes_594603(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594605 = header.getOrDefault("X-Amz-Date")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Date", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Security-Token")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Security-Token", valid_594606
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594607 = header.getOrDefault("X-Amz-Target")
  valid_594607 = validateParameter(valid_594607, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveIpRoutes"))
  if valid_594607 != nil:
    section.add "X-Amz-Target", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Content-Sha256", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Algorithm")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Algorithm", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Signature")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Signature", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-SignedHeaders", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Credential")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Credential", valid_594612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594614: Call_RemoveIpRoutes_594602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes IP address blocks from a directory.
  ## 
  let valid = call_594614.validator(path, query, header, formData, body)
  let scheme = call_594614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594614.url(scheme.get, call_594614.host, call_594614.base,
                         call_594614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594614, url, valid)

proc call*(call_594615: Call_RemoveIpRoutes_594602; body: JsonNode): Recallable =
  ## removeIpRoutes
  ## Removes IP address blocks from a directory.
  ##   body: JObject (required)
  var body_594616 = newJObject()
  if body != nil:
    body_594616 = body
  result = call_594615.call(nil, nil, nil, nil, body_594616)

var removeIpRoutes* = Call_RemoveIpRoutes_594602(name: "removeIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveIpRoutes",
    validator: validate_RemoveIpRoutes_594603, base: "/", url: url_RemoveIpRoutes_594604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_594617 = ref object of OpenApiRestCall_593437
proc url_RemoveTagsFromResource_594619(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromResource_594618(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594620 = header.getOrDefault("X-Amz-Date")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Date", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Security-Token")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Security-Token", valid_594621
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594622 = header.getOrDefault("X-Amz-Target")
  valid_594622 = validateParameter(valid_594622, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveTagsFromResource"))
  if valid_594622 != nil:
    section.add "X-Amz-Target", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Content-Sha256", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Algorithm")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Algorithm", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Signature")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Signature", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-SignedHeaders", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Credential")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Credential", valid_594627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594629: Call_RemoveTagsFromResource_594617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a directory.
  ## 
  let valid = call_594629.validator(path, query, header, formData, body)
  let scheme = call_594629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594629.url(scheme.get, call_594629.host, call_594629.base,
                         call_594629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594629, url, valid)

proc call*(call_594630: Call_RemoveTagsFromResource_594617; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tags from a directory.
  ##   body: JObject (required)
  var body_594631 = newJObject()
  if body != nil:
    body_594631 = body
  result = call_594630.call(nil, nil, nil, nil, body_594631)

var removeTagsFromResource* = Call_RemoveTagsFromResource_594617(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_594618, base: "/",
    url: url_RemoveTagsFromResource_594619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetUserPassword_594632 = ref object of OpenApiRestCall_593437
proc url_ResetUserPassword_594634(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetUserPassword_594633(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.
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
  var valid_594635 = header.getOrDefault("X-Amz-Date")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Date", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Security-Token")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Security-Token", valid_594636
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594637 = header.getOrDefault("X-Amz-Target")
  valid_594637 = validateParameter(valid_594637, JString, required = true, default = newJString(
      "DirectoryService_20150416.ResetUserPassword"))
  if valid_594637 != nil:
    section.add "X-Amz-Target", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Content-Sha256", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Algorithm")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Algorithm", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Signature")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Signature", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-SignedHeaders", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Credential")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Credential", valid_594642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594644: Call_ResetUserPassword_594632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.
  ## 
  let valid = call_594644.validator(path, query, header, formData, body)
  let scheme = call_594644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594644.url(scheme.get, call_594644.host, call_594644.base,
                         call_594644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594644, url, valid)

proc call*(call_594645: Call_ResetUserPassword_594632; body: JsonNode): Recallable =
  ## resetUserPassword
  ## Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.
  ##   body: JObject (required)
  var body_594646 = newJObject()
  if body != nil:
    body_594646 = body
  result = call_594645.call(nil, nil, nil, nil, body_594646)

var resetUserPassword* = Call_ResetUserPassword_594632(name: "resetUserPassword",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ResetUserPassword",
    validator: validate_ResetUserPassword_594633, base: "/",
    url: url_ResetUserPassword_594634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreFromSnapshot_594647 = ref object of OpenApiRestCall_593437
proc url_RestoreFromSnapshot_594649(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreFromSnapshot_594648(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594650 = header.getOrDefault("X-Amz-Date")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Date", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Security-Token")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Security-Token", valid_594651
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594652 = header.getOrDefault("X-Amz-Target")
  valid_594652 = validateParameter(valid_594652, JString, required = true, default = newJString(
      "DirectoryService_20150416.RestoreFromSnapshot"))
  if valid_594652 != nil:
    section.add "X-Amz-Target", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Content-Sha256", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Algorithm")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Algorithm", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Signature")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Signature", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-SignedHeaders", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Credential")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Credential", valid_594657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594659: Call_RestoreFromSnapshot_594647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ## 
  let valid = call_594659.validator(path, query, header, formData, body)
  let scheme = call_594659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594659.url(scheme.get, call_594659.host, call_594659.base,
                         call_594659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594659, url, valid)

proc call*(call_594660: Call_RestoreFromSnapshot_594647; body: JsonNode): Recallable =
  ## restoreFromSnapshot
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ##   body: JObject (required)
  var body_594661 = newJObject()
  if body != nil:
    body_594661 = body
  result = call_594660.call(nil, nil, nil, nil, body_594661)

var restoreFromSnapshot* = Call_RestoreFromSnapshot_594647(
    name: "restoreFromSnapshot", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RestoreFromSnapshot",
    validator: validate_RestoreFromSnapshot_594648, base: "/",
    url: url_RestoreFromSnapshot_594649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShareDirectory_594662 = ref object of OpenApiRestCall_593437
proc url_ShareDirectory_594664(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ShareDirectory_594663(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594665 = header.getOrDefault("X-Amz-Date")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Date", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Security-Token")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Security-Token", valid_594666
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594667 = header.getOrDefault("X-Amz-Target")
  valid_594667 = validateParameter(valid_594667, JString, required = true, default = newJString(
      "DirectoryService_20150416.ShareDirectory"))
  if valid_594667 != nil:
    section.add "X-Amz-Target", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Content-Sha256", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Algorithm")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Algorithm", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Signature")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Signature", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-SignedHeaders", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Credential")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Credential", valid_594672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594674: Call_ShareDirectory_594662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ## 
  let valid = call_594674.validator(path, query, header, formData, body)
  let scheme = call_594674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594674.url(scheme.get, call_594674.host, call_594674.base,
                         call_594674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594674, url, valid)

proc call*(call_594675: Call_ShareDirectory_594662; body: JsonNode): Recallable =
  ## shareDirectory
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ##   body: JObject (required)
  var body_594676 = newJObject()
  if body != nil:
    body_594676 = body
  result = call_594675.call(nil, nil, nil, nil, body_594676)

var shareDirectory* = Call_ShareDirectory_594662(name: "shareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ShareDirectory",
    validator: validate_ShareDirectory_594663, base: "/", url: url_ShareDirectory_594664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaExtension_594677 = ref object of OpenApiRestCall_593437
proc url_StartSchemaExtension_594679(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSchemaExtension_594678(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594680 = header.getOrDefault("X-Amz-Date")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Date", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Security-Token")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Security-Token", valid_594681
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594682 = header.getOrDefault("X-Amz-Target")
  valid_594682 = validateParameter(valid_594682, JString, required = true, default = newJString(
      "DirectoryService_20150416.StartSchemaExtension"))
  if valid_594682 != nil:
    section.add "X-Amz-Target", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Content-Sha256", valid_594683
  var valid_594684 = header.getOrDefault("X-Amz-Algorithm")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Algorithm", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Signature")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Signature", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-SignedHeaders", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Credential")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Credential", valid_594687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594689: Call_StartSchemaExtension_594677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a schema extension to a Microsoft AD directory.
  ## 
  let valid = call_594689.validator(path, query, header, formData, body)
  let scheme = call_594689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594689.url(scheme.get, call_594689.host, call_594689.base,
                         call_594689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594689, url, valid)

proc call*(call_594690: Call_StartSchemaExtension_594677; body: JsonNode): Recallable =
  ## startSchemaExtension
  ## Applies a schema extension to a Microsoft AD directory.
  ##   body: JObject (required)
  var body_594691 = newJObject()
  if body != nil:
    body_594691 = body
  result = call_594690.call(nil, nil, nil, nil, body_594691)

var startSchemaExtension* = Call_StartSchemaExtension_594677(
    name: "startSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.StartSchemaExtension",
    validator: validate_StartSchemaExtension_594678, base: "/",
    url: url_StartSchemaExtension_594679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnshareDirectory_594692 = ref object of OpenApiRestCall_593437
proc url_UnshareDirectory_594694(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UnshareDirectory_594693(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594695 = header.getOrDefault("X-Amz-Date")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Date", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Security-Token")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Security-Token", valid_594696
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594697 = header.getOrDefault("X-Amz-Target")
  valid_594697 = validateParameter(valid_594697, JString, required = true, default = newJString(
      "DirectoryService_20150416.UnshareDirectory"))
  if valid_594697 != nil:
    section.add "X-Amz-Target", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Content-Sha256", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Algorithm")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Algorithm", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Signature")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Signature", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-SignedHeaders", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Credential")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Credential", valid_594702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594704: Call_UnshareDirectory_594692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ## 
  let valid = call_594704.validator(path, query, header, formData, body)
  let scheme = call_594704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594704.url(scheme.get, call_594704.host, call_594704.base,
                         call_594704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594704, url, valid)

proc call*(call_594705: Call_UnshareDirectory_594692; body: JsonNode): Recallable =
  ## unshareDirectory
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ##   body: JObject (required)
  var body_594706 = newJObject()
  if body != nil:
    body_594706 = body
  result = call_594705.call(nil, nil, nil, nil, body_594706)

var unshareDirectory* = Call_UnshareDirectory_594692(name: "unshareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UnshareDirectory",
    validator: validate_UnshareDirectory_594693, base: "/",
    url: url_UnshareDirectory_594694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConditionalForwarder_594707 = ref object of OpenApiRestCall_593437
proc url_UpdateConditionalForwarder_594709(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConditionalForwarder_594708(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594710 = header.getOrDefault("X-Amz-Date")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Date", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Security-Token")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Security-Token", valid_594711
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594712 = header.getOrDefault("X-Amz-Target")
  valid_594712 = validateParameter(valid_594712, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateConditionalForwarder"))
  if valid_594712 != nil:
    section.add "X-Amz-Target", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Content-Sha256", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Algorithm")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Algorithm", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Signature")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Signature", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-SignedHeaders", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Credential")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Credential", valid_594717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594719: Call_UpdateConditionalForwarder_594707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_594719.validator(path, query, header, formData, body)
  let scheme = call_594719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594719.url(scheme.get, call_594719.host, call_594719.base,
                         call_594719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594719, url, valid)

proc call*(call_594720: Call_UpdateConditionalForwarder_594707; body: JsonNode): Recallable =
  ## updateConditionalForwarder
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_594721 = newJObject()
  if body != nil:
    body_594721 = body
  result = call_594720.call(nil, nil, nil, nil, body_594721)

var updateConditionalForwarder* = Call_UpdateConditionalForwarder_594707(
    name: "updateConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateConditionalForwarder",
    validator: validate_UpdateConditionalForwarder_594708, base: "/",
    url: url_UpdateConditionalForwarder_594709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNumberOfDomainControllers_594722 = ref object of OpenApiRestCall_593437
proc url_UpdateNumberOfDomainControllers_594724(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNumberOfDomainControllers_594723(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594725 = header.getOrDefault("X-Amz-Date")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Date", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Security-Token")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Security-Token", valid_594726
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594727 = header.getOrDefault("X-Amz-Target")
  valid_594727 = validateParameter(valid_594727, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateNumberOfDomainControllers"))
  if valid_594727 != nil:
    section.add "X-Amz-Target", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Content-Sha256", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Algorithm")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Algorithm", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Signature")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Signature", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-SignedHeaders", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Credential")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Credential", valid_594732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594734: Call_UpdateNumberOfDomainControllers_594722;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ## 
  let valid = call_594734.validator(path, query, header, formData, body)
  let scheme = call_594734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594734.url(scheme.get, call_594734.host, call_594734.base,
                         call_594734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594734, url, valid)

proc call*(call_594735: Call_UpdateNumberOfDomainControllers_594722; body: JsonNode): Recallable =
  ## updateNumberOfDomainControllers
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ##   body: JObject (required)
  var body_594736 = newJObject()
  if body != nil:
    body_594736 = body
  result = call_594735.call(nil, nil, nil, nil, body_594736)

var updateNumberOfDomainControllers* = Call_UpdateNumberOfDomainControllers_594722(
    name: "updateNumberOfDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateNumberOfDomainControllers",
    validator: validate_UpdateNumberOfDomainControllers_594723, base: "/",
    url: url_UpdateNumberOfDomainControllers_594724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRadius_594737 = ref object of OpenApiRestCall_593437
proc url_UpdateRadius_594739(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRadius_594738(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594740 = header.getOrDefault("X-Amz-Date")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Date", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Security-Token")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Security-Token", valid_594741
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594742 = header.getOrDefault("X-Amz-Target")
  valid_594742 = validateParameter(valid_594742, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateRadius"))
  if valid_594742 != nil:
    section.add "X-Amz-Target", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Content-Sha256", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Algorithm")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Algorithm", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Signature")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Signature", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-SignedHeaders", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Credential")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Credential", valid_594747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594749: Call_UpdateRadius_594737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_594749.validator(path, query, header, formData, body)
  let scheme = call_594749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594749.url(scheme.get, call_594749.host, call_594749.base,
                         call_594749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594749, url, valid)

proc call*(call_594750: Call_UpdateRadius_594737; body: JsonNode): Recallable =
  ## updateRadius
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_594751 = newJObject()
  if body != nil:
    body_594751 = body
  result = call_594750.call(nil, nil, nil, nil, body_594751)

var updateRadius* = Call_UpdateRadius_594737(name: "updateRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UpdateRadius",
    validator: validate_UpdateRadius_594738, base: "/", url: url_UpdateRadius_594739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrust_594752 = ref object of OpenApiRestCall_593437
proc url_UpdateTrust_594754(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTrust_594753(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594755 = header.getOrDefault("X-Amz-Date")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Date", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Security-Token")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Security-Token", valid_594756
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594757 = header.getOrDefault("X-Amz-Target")
  valid_594757 = validateParameter(valid_594757, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateTrust"))
  if valid_594757 != nil:
    section.add "X-Amz-Target", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Content-Sha256", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Algorithm")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Algorithm", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Signature")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Signature", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-SignedHeaders", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Credential")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Credential", valid_594762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594764: Call_UpdateTrust_594752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ## 
  let valid = call_594764.validator(path, query, header, formData, body)
  let scheme = call_594764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594764.url(scheme.get, call_594764.host, call_594764.base,
                         call_594764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594764, url, valid)

proc call*(call_594765: Call_UpdateTrust_594752; body: JsonNode): Recallable =
  ## updateTrust
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ##   body: JObject (required)
  var body_594766 = newJObject()
  if body != nil:
    body_594766 = body
  result = call_594765.call(nil, nil, nil, nil, body_594766)

var updateTrust* = Call_UpdateTrust_594752(name: "updateTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateTrust",
                                        validator: validate_UpdateTrust_594753,
                                        base: "/", url: url_UpdateTrust_594754,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyTrust_594767 = ref object of OpenApiRestCall_593437
proc url_VerifyTrust_594769(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_VerifyTrust_594768(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594770 = header.getOrDefault("X-Amz-Date")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Date", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Security-Token")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Security-Token", valid_594771
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594772 = header.getOrDefault("X-Amz-Target")
  valid_594772 = validateParameter(valid_594772, JString, required = true, default = newJString(
      "DirectoryService_20150416.VerifyTrust"))
  if valid_594772 != nil:
    section.add "X-Amz-Target", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Content-Sha256", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Algorithm")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Algorithm", valid_594774
  var valid_594775 = header.getOrDefault("X-Amz-Signature")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Signature", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-SignedHeaders", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Credential")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Credential", valid_594777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594779: Call_VerifyTrust_594767; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ## 
  let valid = call_594779.validator(path, query, header, formData, body)
  let scheme = call_594779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594779.url(scheme.get, call_594779.host, call_594779.base,
                         call_594779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594779, url, valid)

proc call*(call_594780: Call_VerifyTrust_594767; body: JsonNode): Recallable =
  ## verifyTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ##   body: JObject (required)
  var body_594781 = newJObject()
  if body != nil:
    body_594781 = body
  result = call_594780.call(nil, nil, nil, nil, body_594781)

var verifyTrust* = Call_VerifyTrust_594767(name: "verifyTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.VerifyTrust",
                                        validator: validate_VerifyTrust_594768,
                                        base: "/", url: url_VerifyTrust_594769,
                                        schemes: {Scheme.Https, Scheme.Http})
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
