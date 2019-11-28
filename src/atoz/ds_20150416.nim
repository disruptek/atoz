
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
  Call_AcceptSharedDirectory_599705 = ref object of OpenApiRestCall_599368
proc url_AcceptSharedDirectory_599707(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptSharedDirectory_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "DirectoryService_20150416.AcceptSharedDirectory"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AcceptSharedDirectory_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AcceptSharedDirectory_599705; body: JsonNode): Recallable =
  ## acceptSharedDirectory
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var acceptSharedDirectory* = Call_AcceptSharedDirectory_599705(
    name: "acceptSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AcceptSharedDirectory",
    validator: validate_AcceptSharedDirectory_599706, base: "/",
    url: url_AcceptSharedDirectory_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddIpRoutes_599974 = ref object of OpenApiRestCall_599368
proc url_AddIpRoutes_599976(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddIpRoutes_599975(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "DirectoryService_20150416.AddIpRoutes"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_AddIpRoutes_599974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_AddIpRoutes_599974; body: JsonNode): Recallable =
  ## addIpRoutes
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var addIpRoutes* = Call_AddIpRoutes_599974(name: "addIpRoutes",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.AddIpRoutes",
                                        validator: validate_AddIpRoutes_599975,
                                        base: "/", url: url_AddIpRoutes_599976,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_599989 = ref object of OpenApiRestCall_599368
proc url_AddTagsToResource_599991(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "DirectoryService_20150416.AddTagsToResource"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_AddTagsToResource_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_AddTagsToResource_599989; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var addTagsToResource* = Call_AddTagsToResource_599989(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AddTagsToResource",
    validator: validate_AddTagsToResource_599990, base: "/",
    url: url_AddTagsToResource_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSchemaExtension_600004 = ref object of OpenApiRestCall_599368
proc url_CancelSchemaExtension_600006(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelSchemaExtension_600005(path: JsonNode; query: JsonNode;
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "DirectoryService_20150416.CancelSchemaExtension"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_CancelSchemaExtension_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CancelSchemaExtension_600004; body: JsonNode): Recallable =
  ## cancelSchemaExtension
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var cancelSchemaExtension* = Call_CancelSchemaExtension_600004(
    name: "cancelSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CancelSchemaExtension",
    validator: validate_CancelSchemaExtension_600005, base: "/",
    url: url_CancelSchemaExtension_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectDirectory_600019 = ref object of OpenApiRestCall_599368
proc url_ConnectDirectory_600021(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConnectDirectory_600020(path: JsonNode; query: JsonNode;
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "DirectoryService_20150416.ConnectDirectory"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_ConnectDirectory_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_ConnectDirectory_600019; body: JsonNode): Recallable =
  ## connectDirectory
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var connectDirectory* = Call_ConnectDirectory_600019(name: "connectDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ConnectDirectory",
    validator: validate_ConnectDirectory_600020, base: "/",
    url: url_ConnectDirectory_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_600034 = ref object of OpenApiRestCall_599368
proc url_CreateAlias_600036(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlias_600035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateAlias"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_CreateAlias_600034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_CreateAlias_600034; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var createAlias* = Call_CreateAlias_600034(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateAlias",
                                        validator: validate_CreateAlias_600035,
                                        base: "/", url: url_CreateAlias_600036,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputer_600049 = ref object of OpenApiRestCall_599368
proc url_CreateComputer_600051(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComputer_600050(path: JsonNode; query: JsonNode;
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateComputer"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_CreateComputer_600049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_CreateComputer_600049; body: JsonNode): Recallable =
  ## createComputer
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var createComputer* = Call_CreateComputer_600049(name: "createComputer",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateComputer",
    validator: validate_CreateComputer_600050, base: "/", url: url_CreateComputer_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConditionalForwarder_600064 = ref object of OpenApiRestCall_599368
proc url_CreateConditionalForwarder_600066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConditionalForwarder_600065(path: JsonNode; query: JsonNode;
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateConditionalForwarder"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_CreateConditionalForwarder_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_CreateConditionalForwarder_600064; body: JsonNode): Recallable =
  ## createConditionalForwarder
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var createConditionalForwarder* = Call_CreateConditionalForwarder_600064(
    name: "createConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateConditionalForwarder",
    validator: validate_CreateConditionalForwarder_600065, base: "/",
    url: url_CreateConditionalForwarder_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_600079 = ref object of OpenApiRestCall_599368
proc url_CreateDirectory_600081(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectory_600080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateDirectory"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_CreateDirectory_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_CreateDirectory_600079; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var createDirectory* = Call_CreateDirectory_600079(name: "createDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateDirectory",
    validator: validate_CreateDirectory_600080, base: "/", url: url_CreateDirectory_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogSubscription_600094 = ref object of OpenApiRestCall_599368
proc url_CreateLogSubscription_600096(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLogSubscription_600095(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateLogSubscription"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_CreateLogSubscription_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_CreateLogSubscription_600094; body: JsonNode): Recallable =
  ## createLogSubscription
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var createLogSubscription* = Call_CreateLogSubscription_600094(
    name: "createLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateLogSubscription",
    validator: validate_CreateLogSubscription_600095, base: "/",
    url: url_CreateLogSubscription_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMicrosoftAD_600109 = ref object of OpenApiRestCall_599368
proc url_CreateMicrosoftAD_600111(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMicrosoftAD_600110(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateMicrosoftAD"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_CreateMicrosoftAD_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_CreateMicrosoftAD_600109; body: JsonNode): Recallable =
  ## createMicrosoftAD
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var createMicrosoftAD* = Call_CreateMicrosoftAD_600109(name: "createMicrosoftAD",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateMicrosoftAD",
    validator: validate_CreateMicrosoftAD_600110, base: "/",
    url: url_CreateMicrosoftAD_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_600124 = ref object of OpenApiRestCall_599368
proc url_CreateSnapshot_600126(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSnapshot_600125(path: JsonNode; query: JsonNode;
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateSnapshot"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_CreateSnapshot_600124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_CreateSnapshot_600124; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var createSnapshot* = Call_CreateSnapshot_600124(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateSnapshot",
    validator: validate_CreateSnapshot_600125, base: "/", url: url_CreateSnapshot_600126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrust_600139 = ref object of OpenApiRestCall_599368
proc url_CreateTrust_600141(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrust_600140(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateTrust"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_CreateTrust_600139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_CreateTrust_600139; body: JsonNode): Recallable =
  ## createTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var createTrust* = Call_CreateTrust_600139(name: "createTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateTrust",
                                        validator: validate_CreateTrust_600140,
                                        base: "/", url: url_CreateTrust_600141,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConditionalForwarder_600154 = ref object of OpenApiRestCall_599368
proc url_DeleteConditionalForwarder_600156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConditionalForwarder_600155(path: JsonNode; query: JsonNode;
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteConditionalForwarder"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_DeleteConditionalForwarder_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_DeleteConditionalForwarder_600154; body: JsonNode): Recallable =
  ## deleteConditionalForwarder
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var deleteConditionalForwarder* = Call_DeleteConditionalForwarder_600154(
    name: "deleteConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteConditionalForwarder",
    validator: validate_DeleteConditionalForwarder_600155, base: "/",
    url: url_DeleteConditionalForwarder_600156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_600169 = ref object of OpenApiRestCall_599368
proc url_DeleteDirectory_600171(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectory_600170(path: JsonNode; query: JsonNode;
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteDirectory"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_DeleteDirectory_600169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_DeleteDirectory_600169; body: JsonNode): Recallable =
  ## deleteDirectory
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var deleteDirectory* = Call_DeleteDirectory_600169(name: "deleteDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteDirectory",
    validator: validate_DeleteDirectory_600170, base: "/", url: url_DeleteDirectory_600171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogSubscription_600184 = ref object of OpenApiRestCall_599368
proc url_DeleteLogSubscription_600186(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLogSubscription_600185(path: JsonNode; query: JsonNode;
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
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600189 = header.getOrDefault("X-Amz-Target")
  valid_600189 = validateParameter(valid_600189, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteLogSubscription"))
  if valid_600189 != nil:
    section.add "X-Amz-Target", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_DeleteLogSubscription_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log subscription.
  ## 
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_DeleteLogSubscription_600184; body: JsonNode): Recallable =
  ## deleteLogSubscription
  ## Deletes the specified log subscription.
  ##   body: JObject (required)
  var body_600198 = newJObject()
  if body != nil:
    body_600198 = body
  result = call_600197.call(nil, nil, nil, nil, body_600198)

var deleteLogSubscription* = Call_DeleteLogSubscription_600184(
    name: "deleteLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteLogSubscription",
    validator: validate_DeleteLogSubscription_600185, base: "/",
    url: url_DeleteLogSubscription_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshot_600199 = ref object of OpenApiRestCall_599368
proc url_DeleteSnapshot_600201(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSnapshot_600200(path: JsonNode; query: JsonNode;
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
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600204 = header.getOrDefault("X-Amz-Target")
  valid_600204 = validateParameter(valid_600204, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteSnapshot"))
  if valid_600204 != nil:
    section.add "X-Amz-Target", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_DeleteSnapshot_600199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory snapshot.
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_DeleteSnapshot_600199; body: JsonNode): Recallable =
  ## deleteSnapshot
  ## Deletes a directory snapshot.
  ##   body: JObject (required)
  var body_600213 = newJObject()
  if body != nil:
    body_600213 = body
  result = call_600212.call(nil, nil, nil, nil, body_600213)

var deleteSnapshot* = Call_DeleteSnapshot_600199(name: "deleteSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteSnapshot",
    validator: validate_DeleteSnapshot_600200, base: "/", url: url_DeleteSnapshot_600201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrust_600214 = ref object of OpenApiRestCall_599368
proc url_DeleteTrust_600216(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrust_600215(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600219 = header.getOrDefault("X-Amz-Target")
  valid_600219 = validateParameter(valid_600219, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteTrust"))
  if valid_600219 != nil:
    section.add "X-Amz-Target", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_DeleteTrust_600214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_DeleteTrust_600214; body: JsonNode): Recallable =
  ## deleteTrust
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ##   body: JObject (required)
  var body_600228 = newJObject()
  if body != nil:
    body_600228 = body
  result = call_600227.call(nil, nil, nil, nil, body_600228)

var deleteTrust* = Call_DeleteTrust_600214(name: "deleteTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteTrust",
                                        validator: validate_DeleteTrust_600215,
                                        base: "/", url: url_DeleteTrust_600216,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterCertificate_600229 = ref object of OpenApiRestCall_599368
proc url_DeregisterCertificate_600231(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterCertificate_600230(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600234 = header.getOrDefault("X-Amz-Target")
  valid_600234 = validateParameter(valid_600234, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterCertificate"))
  if valid_600234 != nil:
    section.add "X-Amz-Target", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_DeregisterCertificate_600229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_DeregisterCertificate_600229; body: JsonNode): Recallable =
  ## deregisterCertificate
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var deregisterCertificate* = Call_DeregisterCertificate_600229(
    name: "deregisterCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterCertificate",
    validator: validate_DeregisterCertificate_600230, base: "/",
    url: url_DeregisterCertificate_600231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterEventTopic_600244 = ref object of OpenApiRestCall_599368
proc url_DeregisterEventTopic_600246(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterEventTopic_600245(path: JsonNode; query: JsonNode;
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
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterEventTopic"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_DeregisterEventTopic_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_DeregisterEventTopic_600244; body: JsonNode): Recallable =
  ## deregisterEventTopic
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ##   body: JObject (required)
  var body_600258 = newJObject()
  if body != nil:
    body_600258 = body
  result = call_600257.call(nil, nil, nil, nil, body_600258)

var deregisterEventTopic* = Call_DeregisterEventTopic_600244(
    name: "deregisterEventTopic", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterEventTopic",
    validator: validate_DeregisterEventTopic_600245, base: "/",
    url: url_DeregisterEventTopic_600246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificate_600259 = ref object of OpenApiRestCall_599368
proc url_DescribeCertificate_600261(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCertificate_600260(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600264 = header.getOrDefault("X-Amz-Target")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeCertificate"))
  if valid_600264 != nil:
    section.add "X-Amz-Target", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600271: Call_DescribeCertificate_600259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays information about the certificate registered for a secured LDAP connection.
  ## 
  let valid = call_600271.validator(path, query, header, formData, body)
  let scheme = call_600271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600271.url(scheme.get, call_600271.host, call_600271.base,
                         call_600271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600271, url, valid)

proc call*(call_600272: Call_DescribeCertificate_600259; body: JsonNode): Recallable =
  ## describeCertificate
  ## Displays information about the certificate registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_600273 = newJObject()
  if body != nil:
    body_600273 = body
  result = call_600272.call(nil, nil, nil, nil, body_600273)

var describeCertificate* = Call_DescribeCertificate_600259(
    name: "describeCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeCertificate",
    validator: validate_DescribeCertificate_600260, base: "/",
    url: url_DescribeCertificate_600261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConditionalForwarders_600274 = ref object of OpenApiRestCall_599368
proc url_DescribeConditionalForwarders_600276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConditionalForwarders_600275(path: JsonNode; query: JsonNode;
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeConditionalForwarders"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_DescribeConditionalForwarders_600274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_DescribeConditionalForwarders_600274; body: JsonNode): Recallable =
  ## describeConditionalForwarders
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ##   body: JObject (required)
  var body_600288 = newJObject()
  if body != nil:
    body_600288 = body
  result = call_600287.call(nil, nil, nil, nil, body_600288)

var describeConditionalForwarders* = Call_DescribeConditionalForwarders_600274(
    name: "describeConditionalForwarders", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeConditionalForwarders",
    validator: validate_DescribeConditionalForwarders_600275, base: "/",
    url: url_DescribeConditionalForwarders_600276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectories_600289 = ref object of OpenApiRestCall_599368
proc url_DescribeDirectories_600291(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectories_600290(path: JsonNode; query: JsonNode;
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600294 = header.getOrDefault("X-Amz-Target")
  valid_600294 = validateParameter(valid_600294, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDirectories"))
  if valid_600294 != nil:
    section.add "X-Amz-Target", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_DescribeDirectories_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_DescribeDirectories_600289; body: JsonNode): Recallable =
  ## describeDirectories
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var describeDirectories* = Call_DescribeDirectories_600289(
    name: "describeDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDirectories",
    validator: validate_DescribeDirectories_600290, base: "/",
    url: url_DescribeDirectories_600291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomainControllers_600304 = ref object of OpenApiRestCall_599368
proc url_DescribeDomainControllers_600306(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomainControllers_600305(path: JsonNode; query: JsonNode;
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
  var valid_600307 = query.getOrDefault("Limit")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "Limit", valid_600307
  var valid_600308 = query.getOrDefault("NextToken")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "NextToken", valid_600308
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
  var valid_600309 = header.getOrDefault("X-Amz-Date")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Date", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Security-Token")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Security-Token", valid_600310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600311 = header.getOrDefault("X-Amz-Target")
  valid_600311 = validateParameter(valid_600311, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDomainControllers"))
  if valid_600311 != nil:
    section.add "X-Amz-Target", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Content-Sha256", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Algorithm")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Algorithm", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Signature")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Signature", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-SignedHeaders", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Credential")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Credential", valid_600316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600318: Call_DescribeDomainControllers_600304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about any domain controllers in your directory.
  ## 
  let valid = call_600318.validator(path, query, header, formData, body)
  let scheme = call_600318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600318.url(scheme.get, call_600318.host, call_600318.base,
                         call_600318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600318, url, valid)

proc call*(call_600319: Call_DescribeDomainControllers_600304; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeDomainControllers
  ## Provides information about any domain controllers in your directory.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600320 = newJObject()
  var body_600321 = newJObject()
  add(query_600320, "Limit", newJString(Limit))
  add(query_600320, "NextToken", newJString(NextToken))
  if body != nil:
    body_600321 = body
  result = call_600319.call(nil, query_600320, nil, nil, body_600321)

var describeDomainControllers* = Call_DescribeDomainControllers_600304(
    name: "describeDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDomainControllers",
    validator: validate_DescribeDomainControllers_600305, base: "/",
    url: url_DescribeDomainControllers_600306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTopics_600323 = ref object of OpenApiRestCall_599368
proc url_DescribeEventTopics_600325(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventTopics_600324(path: JsonNode; query: JsonNode;
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
  var valid_600326 = header.getOrDefault("X-Amz-Date")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Date", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Security-Token")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Security-Token", valid_600327
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600328 = header.getOrDefault("X-Amz-Target")
  valid_600328 = validateParameter(valid_600328, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeEventTopics"))
  if valid_600328 != nil:
    section.add "X-Amz-Target", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Content-Sha256", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Algorithm")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Algorithm", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Signature")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Signature", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-SignedHeaders", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Credential")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Credential", valid_600333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600335: Call_DescribeEventTopics_600323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ## 
  let valid = call_600335.validator(path, query, header, formData, body)
  let scheme = call_600335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600335.url(scheme.get, call_600335.host, call_600335.base,
                         call_600335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600335, url, valid)

proc call*(call_600336: Call_DescribeEventTopics_600323; body: JsonNode): Recallable =
  ## describeEventTopics
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ##   body: JObject (required)
  var body_600337 = newJObject()
  if body != nil:
    body_600337 = body
  result = call_600336.call(nil, nil, nil, nil, body_600337)

var describeEventTopics* = Call_DescribeEventTopics_600323(
    name: "describeEventTopics", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeEventTopics",
    validator: validate_DescribeEventTopics_600324, base: "/",
    url: url_DescribeEventTopics_600325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLDAPSSettings_600338 = ref object of OpenApiRestCall_599368
proc url_DescribeLDAPSSettings_600340(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLDAPSSettings_600339(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600341 = header.getOrDefault("X-Amz-Date")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Date", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Security-Token")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Security-Token", valid_600342
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600343 = header.getOrDefault("X-Amz-Target")
  valid_600343 = validateParameter(valid_600343, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeLDAPSSettings"))
  if valid_600343 != nil:
    section.add "X-Amz-Target", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Content-Sha256", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Algorithm")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Algorithm", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Signature")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Signature", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-SignedHeaders", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Credential")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Credential", valid_600348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600350: Call_DescribeLDAPSSettings_600338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of LDAP security for the specified directory.
  ## 
  let valid = call_600350.validator(path, query, header, formData, body)
  let scheme = call_600350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600350.url(scheme.get, call_600350.host, call_600350.base,
                         call_600350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600350, url, valid)

proc call*(call_600351: Call_DescribeLDAPSSettings_600338; body: JsonNode): Recallable =
  ## describeLDAPSSettings
  ## Describes the status of LDAP security for the specified directory.
  ##   body: JObject (required)
  var body_600352 = newJObject()
  if body != nil:
    body_600352 = body
  result = call_600351.call(nil, nil, nil, nil, body_600352)

var describeLDAPSSettings* = Call_DescribeLDAPSSettings_600338(
    name: "describeLDAPSSettings", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeLDAPSSettings",
    validator: validate_DescribeLDAPSSettings_600339, base: "/",
    url: url_DescribeLDAPSSettings_600340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSharedDirectories_600353 = ref object of OpenApiRestCall_599368
proc url_DescribeSharedDirectories_600355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSharedDirectories_600354(path: JsonNode; query: JsonNode;
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
  var valid_600356 = header.getOrDefault("X-Amz-Date")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Date", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Security-Token")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Security-Token", valid_600357
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600358 = header.getOrDefault("X-Amz-Target")
  valid_600358 = validateParameter(valid_600358, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSharedDirectories"))
  if valid_600358 != nil:
    section.add "X-Amz-Target", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Content-Sha256", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Algorithm")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Algorithm", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Signature")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Signature", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-SignedHeaders", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Credential")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Credential", valid_600363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600365: Call_DescribeSharedDirectories_600353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the shared directories in your account. 
  ## 
  let valid = call_600365.validator(path, query, header, formData, body)
  let scheme = call_600365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600365.url(scheme.get, call_600365.host, call_600365.base,
                         call_600365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600365, url, valid)

proc call*(call_600366: Call_DescribeSharedDirectories_600353; body: JsonNode): Recallable =
  ## describeSharedDirectories
  ## Returns the shared directories in your account. 
  ##   body: JObject (required)
  var body_600367 = newJObject()
  if body != nil:
    body_600367 = body
  result = call_600366.call(nil, nil, nil, nil, body_600367)

var describeSharedDirectories* = Call_DescribeSharedDirectories_600353(
    name: "describeSharedDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSharedDirectories",
    validator: validate_DescribeSharedDirectories_600354, base: "/",
    url: url_DescribeSharedDirectories_600355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshots_600368 = ref object of OpenApiRestCall_599368
proc url_DescribeSnapshots_600370(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSnapshots_600369(path: JsonNode; query: JsonNode;
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
  var valid_600371 = header.getOrDefault("X-Amz-Date")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Date", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Security-Token")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Security-Token", valid_600372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600373 = header.getOrDefault("X-Amz-Target")
  valid_600373 = validateParameter(valid_600373, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSnapshots"))
  if valid_600373 != nil:
    section.add "X-Amz-Target", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Content-Sha256", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Algorithm")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Algorithm", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Signature")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Signature", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-SignedHeaders", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Credential")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Credential", valid_600378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600380: Call_DescribeSnapshots_600368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ## 
  let valid = call_600380.validator(path, query, header, formData, body)
  let scheme = call_600380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600380.url(scheme.get, call_600380.host, call_600380.base,
                         call_600380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600380, url, valid)

proc call*(call_600381: Call_DescribeSnapshots_600368; body: JsonNode): Recallable =
  ## describeSnapshots
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ##   body: JObject (required)
  var body_600382 = newJObject()
  if body != nil:
    body_600382 = body
  result = call_600381.call(nil, nil, nil, nil, body_600382)

var describeSnapshots* = Call_DescribeSnapshots_600368(name: "describeSnapshots",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSnapshots",
    validator: validate_DescribeSnapshots_600369, base: "/",
    url: url_DescribeSnapshots_600370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrusts_600383 = ref object of OpenApiRestCall_599368
proc url_DescribeTrusts_600385(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrusts_600384(path: JsonNode; query: JsonNode;
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
  var valid_600386 = header.getOrDefault("X-Amz-Date")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Date", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Security-Token")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Security-Token", valid_600387
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600388 = header.getOrDefault("X-Amz-Target")
  valid_600388 = validateParameter(valid_600388, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeTrusts"))
  if valid_600388 != nil:
    section.add "X-Amz-Target", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Content-Sha256", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Algorithm")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Algorithm", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Signature")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Signature", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-SignedHeaders", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Credential")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Credential", valid_600393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600395: Call_DescribeTrusts_600383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ## 
  let valid = call_600395.validator(path, query, header, formData, body)
  let scheme = call_600395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600395.url(scheme.get, call_600395.host, call_600395.base,
                         call_600395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600395, url, valid)

proc call*(call_600396: Call_DescribeTrusts_600383; body: JsonNode): Recallable =
  ## describeTrusts
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ##   body: JObject (required)
  var body_600397 = newJObject()
  if body != nil:
    body_600397 = body
  result = call_600396.call(nil, nil, nil, nil, body_600397)

var describeTrusts* = Call_DescribeTrusts_600383(name: "describeTrusts",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeTrusts",
    validator: validate_DescribeTrusts_600384, base: "/", url: url_DescribeTrusts_600385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableLDAPS_600398 = ref object of OpenApiRestCall_599368
proc url_DisableLDAPS_600400(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableLDAPS_600399(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600401 = header.getOrDefault("X-Amz-Date")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Date", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Security-Token")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Security-Token", valid_600402
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600403 = header.getOrDefault("X-Amz-Target")
  valid_600403 = validateParameter(valid_600403, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableLDAPS"))
  if valid_600403 != nil:
    section.add "X-Amz-Target", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Content-Sha256", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Algorithm")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Algorithm", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Signature")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Signature", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-SignedHeaders", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Credential")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Credential", valid_600408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600410: Call_DisableLDAPS_600398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates LDAP secure calls for the specified directory.
  ## 
  let valid = call_600410.validator(path, query, header, formData, body)
  let scheme = call_600410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600410.url(scheme.get, call_600410.host, call_600410.base,
                         call_600410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600410, url, valid)

proc call*(call_600411: Call_DisableLDAPS_600398; body: JsonNode): Recallable =
  ## disableLDAPS
  ## Deactivates LDAP secure calls for the specified directory.
  ##   body: JObject (required)
  var body_600412 = newJObject()
  if body != nil:
    body_600412 = body
  result = call_600411.call(nil, nil, nil, nil, body_600412)

var disableLDAPS* = Call_DisableLDAPS_600398(name: "disableLDAPS",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableLDAPS",
    validator: validate_DisableLDAPS_600399, base: "/", url: url_DisableLDAPS_600400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableRadius_600413 = ref object of OpenApiRestCall_599368
proc url_DisableRadius_600415(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableRadius_600414(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600416 = header.getOrDefault("X-Amz-Date")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Date", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Security-Token")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Security-Token", valid_600417
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600418 = header.getOrDefault("X-Amz-Target")
  valid_600418 = validateParameter(valid_600418, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableRadius"))
  if valid_600418 != nil:
    section.add "X-Amz-Target", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Content-Sha256", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Algorithm")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Algorithm", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Signature")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Signature", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-SignedHeaders", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Credential")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Credential", valid_600423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600425: Call_DisableRadius_600413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_600425.validator(path, query, header, formData, body)
  let scheme = call_600425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600425.url(scheme.get, call_600425.host, call_600425.base,
                         call_600425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600425, url, valid)

proc call*(call_600426: Call_DisableRadius_600413; body: JsonNode): Recallable =
  ## disableRadius
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_600427 = newJObject()
  if body != nil:
    body_600427 = body
  result = call_600426.call(nil, nil, nil, nil, body_600427)

var disableRadius* = Call_DisableRadius_600413(name: "disableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableRadius",
    validator: validate_DisableRadius_600414, base: "/", url: url_DisableRadius_600415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSso_600428 = ref object of OpenApiRestCall_599368
proc url_DisableSso_600430(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableSso_600429(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600431 = header.getOrDefault("X-Amz-Date")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Date", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Security-Token")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Security-Token", valid_600432
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600433 = header.getOrDefault("X-Amz-Target")
  valid_600433 = validateParameter(valid_600433, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableSso"))
  if valid_600433 != nil:
    section.add "X-Amz-Target", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Content-Sha256", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Algorithm")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Algorithm", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Signature")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Signature", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-SignedHeaders", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Credential")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Credential", valid_600438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600440: Call_DisableSso_600428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables single-sign on for a directory.
  ## 
  let valid = call_600440.validator(path, query, header, formData, body)
  let scheme = call_600440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600440.url(scheme.get, call_600440.host, call_600440.base,
                         call_600440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600440, url, valid)

proc call*(call_600441: Call_DisableSso_600428; body: JsonNode): Recallable =
  ## disableSso
  ## Disables single-sign on for a directory.
  ##   body: JObject (required)
  var body_600442 = newJObject()
  if body != nil:
    body_600442 = body
  result = call_600441.call(nil, nil, nil, nil, body_600442)

var disableSso* = Call_DisableSso_600428(name: "disableSso",
                                      meth: HttpMethod.HttpPost,
                                      host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DisableSso",
                                      validator: validate_DisableSso_600429,
                                      base: "/", url: url_DisableSso_600430,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableLDAPS_600443 = ref object of OpenApiRestCall_599368
proc url_EnableLDAPS_600445(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableLDAPS_600444(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600446 = header.getOrDefault("X-Amz-Date")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Date", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Security-Token")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Security-Token", valid_600447
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600448 = header.getOrDefault("X-Amz-Target")
  valid_600448 = validateParameter(valid_600448, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableLDAPS"))
  if valid_600448 != nil:
    section.add "X-Amz-Target", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Content-Sha256", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Algorithm")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Algorithm", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Signature")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Signature", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-SignedHeaders", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Credential")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Credential", valid_600453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600455: Call_EnableLDAPS_600443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the switch for the specific directory to always use LDAP secure calls.
  ## 
  let valid = call_600455.validator(path, query, header, formData, body)
  let scheme = call_600455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600455.url(scheme.get, call_600455.host, call_600455.base,
                         call_600455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600455, url, valid)

proc call*(call_600456: Call_EnableLDAPS_600443; body: JsonNode): Recallable =
  ## enableLDAPS
  ## Activates the switch for the specific directory to always use LDAP secure calls.
  ##   body: JObject (required)
  var body_600457 = newJObject()
  if body != nil:
    body_600457 = body
  result = call_600456.call(nil, nil, nil, nil, body_600457)

var enableLDAPS* = Call_EnableLDAPS_600443(name: "enableLDAPS",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableLDAPS",
                                        validator: validate_EnableLDAPS_600444,
                                        base: "/", url: url_EnableLDAPS_600445,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableRadius_600458 = ref object of OpenApiRestCall_599368
proc url_EnableRadius_600460(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableRadius_600459(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600461 = header.getOrDefault("X-Amz-Date")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Date", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Security-Token")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Security-Token", valid_600462
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600463 = header.getOrDefault("X-Amz-Target")
  valid_600463 = validateParameter(valid_600463, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableRadius"))
  if valid_600463 != nil:
    section.add "X-Amz-Target", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Content-Sha256", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Algorithm")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Algorithm", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Signature")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Signature", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-SignedHeaders", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Credential")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Credential", valid_600468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600470: Call_EnableRadius_600458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_600470.validator(path, query, header, formData, body)
  let scheme = call_600470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600470.url(scheme.get, call_600470.host, call_600470.base,
                         call_600470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600470, url, valid)

proc call*(call_600471: Call_EnableRadius_600458; body: JsonNode): Recallable =
  ## enableRadius
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_600472 = newJObject()
  if body != nil:
    body_600472 = body
  result = call_600471.call(nil, nil, nil, nil, body_600472)

var enableRadius* = Call_EnableRadius_600458(name: "enableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.EnableRadius",
    validator: validate_EnableRadius_600459, base: "/", url: url_EnableRadius_600460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSso_600473 = ref object of OpenApiRestCall_599368
proc url_EnableSso_600475(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSso_600474(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600476 = header.getOrDefault("X-Amz-Date")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Date", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Security-Token")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Security-Token", valid_600477
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600478 = header.getOrDefault("X-Amz-Target")
  valid_600478 = validateParameter(valid_600478, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableSso"))
  if valid_600478 != nil:
    section.add "X-Amz-Target", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Content-Sha256", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Algorithm")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Algorithm", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Signature")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Signature", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-SignedHeaders", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Credential")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Credential", valid_600483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600485: Call_EnableSso_600473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
  ## 
  let valid = call_600485.validator(path, query, header, formData, body)
  let scheme = call_600485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600485.url(scheme.get, call_600485.host, call_600485.base,
                         call_600485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600485, url, valid)

proc call*(call_600486: Call_EnableSso_600473; body: JsonNode): Recallable =
  ## enableSso
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
  ##   body: JObject (required)
  var body_600487 = newJObject()
  if body != nil:
    body_600487 = body
  result = call_600486.call(nil, nil, nil, nil, body_600487)

var enableSso* = Call_EnableSso_600473(name: "enableSso", meth: HttpMethod.HttpPost,
                                    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableSso",
                                    validator: validate_EnableSso_600474,
                                    base: "/", url: url_EnableSso_600475,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectoryLimits_600488 = ref object of OpenApiRestCall_599368
proc url_GetDirectoryLimits_600490(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDirectoryLimits_600489(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600491 = header.getOrDefault("X-Amz-Date")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Date", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Security-Token")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Security-Token", valid_600492
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600493 = header.getOrDefault("X-Amz-Target")
  valid_600493 = validateParameter(valid_600493, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetDirectoryLimits"))
  if valid_600493 != nil:
    section.add "X-Amz-Target", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Content-Sha256", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Algorithm")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Algorithm", valid_600495
  var valid_600496 = header.getOrDefault("X-Amz-Signature")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Signature", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-SignedHeaders", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Credential")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Credential", valid_600498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600500: Call_GetDirectoryLimits_600488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains directory limit information for the current Region.
  ## 
  let valid = call_600500.validator(path, query, header, formData, body)
  let scheme = call_600500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600500.url(scheme.get, call_600500.host, call_600500.base,
                         call_600500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600500, url, valid)

proc call*(call_600501: Call_GetDirectoryLimits_600488; body: JsonNode): Recallable =
  ## getDirectoryLimits
  ## Obtains directory limit information for the current Region.
  ##   body: JObject (required)
  var body_600502 = newJObject()
  if body != nil:
    body_600502 = body
  result = call_600501.call(nil, nil, nil, nil, body_600502)

var getDirectoryLimits* = Call_GetDirectoryLimits_600488(
    name: "getDirectoryLimits", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetDirectoryLimits",
    validator: validate_GetDirectoryLimits_600489, base: "/",
    url: url_GetDirectoryLimits_600490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnapshotLimits_600503 = ref object of OpenApiRestCall_599368
proc url_GetSnapshotLimits_600505(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSnapshotLimits_600504(path: JsonNode; query: JsonNode;
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
  var valid_600506 = header.getOrDefault("X-Amz-Date")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Date", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Security-Token")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Security-Token", valid_600507
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600508 = header.getOrDefault("X-Amz-Target")
  valid_600508 = validateParameter(valid_600508, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetSnapshotLimits"))
  if valid_600508 != nil:
    section.add "X-Amz-Target", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Content-Sha256", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Algorithm")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Algorithm", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Signature")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Signature", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-SignedHeaders", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Credential")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Credential", valid_600513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600515: Call_GetSnapshotLimits_600503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains the manual snapshot limits for a directory.
  ## 
  let valid = call_600515.validator(path, query, header, formData, body)
  let scheme = call_600515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600515.url(scheme.get, call_600515.host, call_600515.base,
                         call_600515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600515, url, valid)

proc call*(call_600516: Call_GetSnapshotLimits_600503; body: JsonNode): Recallable =
  ## getSnapshotLimits
  ## Obtains the manual snapshot limits for a directory.
  ##   body: JObject (required)
  var body_600517 = newJObject()
  if body != nil:
    body_600517 = body
  result = call_600516.call(nil, nil, nil, nil, body_600517)

var getSnapshotLimits* = Call_GetSnapshotLimits_600503(name: "getSnapshotLimits",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetSnapshotLimits",
    validator: validate_GetSnapshotLimits_600504, base: "/",
    url: url_GetSnapshotLimits_600505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificates_600518 = ref object of OpenApiRestCall_599368
proc url_ListCertificates_600520(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCertificates_600519(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600521 = header.getOrDefault("X-Amz-Date")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Date", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Security-Token")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Security-Token", valid_600522
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600523 = header.getOrDefault("X-Amz-Target")
  valid_600523 = validateParameter(valid_600523, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListCertificates"))
  if valid_600523 != nil:
    section.add "X-Amz-Target", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Content-Sha256", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Algorithm")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Algorithm", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Signature")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Signature", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-SignedHeaders", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Credential")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Credential", valid_600528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600530: Call_ListCertificates_600518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
  ## 
  let valid = call_600530.validator(path, query, header, formData, body)
  let scheme = call_600530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600530.url(scheme.get, call_600530.host, call_600530.base,
                         call_600530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600530, url, valid)

proc call*(call_600531: Call_ListCertificates_600518; body: JsonNode): Recallable =
  ## listCertificates
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_600532 = newJObject()
  if body != nil:
    body_600532 = body
  result = call_600531.call(nil, nil, nil, nil, body_600532)

var listCertificates* = Call_ListCertificates_600518(name: "listCertificates",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListCertificates",
    validator: validate_ListCertificates_600519, base: "/",
    url: url_ListCertificates_600520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIpRoutes_600533 = ref object of OpenApiRestCall_599368
proc url_ListIpRoutes_600535(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIpRoutes_600534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600536 = header.getOrDefault("X-Amz-Date")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Date", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Security-Token")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Security-Token", valid_600537
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600538 = header.getOrDefault("X-Amz-Target")
  valid_600538 = validateParameter(valid_600538, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListIpRoutes"))
  if valid_600538 != nil:
    section.add "X-Amz-Target", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Content-Sha256", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Algorithm")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Algorithm", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Signature")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Signature", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-SignedHeaders", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Credential")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Credential", valid_600543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600545: Call_ListIpRoutes_600533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the address blocks that you have added to a directory.
  ## 
  let valid = call_600545.validator(path, query, header, formData, body)
  let scheme = call_600545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600545.url(scheme.get, call_600545.host, call_600545.base,
                         call_600545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600545, url, valid)

proc call*(call_600546: Call_ListIpRoutes_600533; body: JsonNode): Recallable =
  ## listIpRoutes
  ## Lists the address blocks that you have added to a directory.
  ##   body: JObject (required)
  var body_600547 = newJObject()
  if body != nil:
    body_600547 = body
  result = call_600546.call(nil, nil, nil, nil, body_600547)

var listIpRoutes* = Call_ListIpRoutes_600533(name: "listIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListIpRoutes",
    validator: validate_ListIpRoutes_600534, base: "/", url: url_ListIpRoutes_600535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogSubscriptions_600548 = ref object of OpenApiRestCall_599368
proc url_ListLogSubscriptions_600550(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogSubscriptions_600549(path: JsonNode; query: JsonNode;
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
  var valid_600551 = header.getOrDefault("X-Amz-Date")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Date", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Security-Token")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Security-Token", valid_600552
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600553 = header.getOrDefault("X-Amz-Target")
  valid_600553 = validateParameter(valid_600553, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListLogSubscriptions"))
  if valid_600553 != nil:
    section.add "X-Amz-Target", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Content-Sha256", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Algorithm")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Algorithm", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Signature")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Signature", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-SignedHeaders", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Credential")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Credential", valid_600558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600560: Call_ListLogSubscriptions_600548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the active log subscriptions for the AWS account.
  ## 
  let valid = call_600560.validator(path, query, header, formData, body)
  let scheme = call_600560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600560.url(scheme.get, call_600560.host, call_600560.base,
                         call_600560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600560, url, valid)

proc call*(call_600561: Call_ListLogSubscriptions_600548; body: JsonNode): Recallable =
  ## listLogSubscriptions
  ## Lists the active log subscriptions for the AWS account.
  ##   body: JObject (required)
  var body_600562 = newJObject()
  if body != nil:
    body_600562 = body
  result = call_600561.call(nil, nil, nil, nil, body_600562)

var listLogSubscriptions* = Call_ListLogSubscriptions_600548(
    name: "listLogSubscriptions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListLogSubscriptions",
    validator: validate_ListLogSubscriptions_600549, base: "/",
    url: url_ListLogSubscriptions_600550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaExtensions_600563 = ref object of OpenApiRestCall_599368
proc url_ListSchemaExtensions_600565(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSchemaExtensions_600564(path: JsonNode; query: JsonNode;
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
  var valid_600566 = header.getOrDefault("X-Amz-Date")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Date", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Security-Token")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Security-Token", valid_600567
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600568 = header.getOrDefault("X-Amz-Target")
  valid_600568 = validateParameter(valid_600568, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListSchemaExtensions"))
  if valid_600568 != nil:
    section.add "X-Amz-Target", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Content-Sha256", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Algorithm")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Algorithm", valid_600570
  var valid_600571 = header.getOrDefault("X-Amz-Signature")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Signature", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-SignedHeaders", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Credential")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Credential", valid_600573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600575: Call_ListSchemaExtensions_600563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ## 
  let valid = call_600575.validator(path, query, header, formData, body)
  let scheme = call_600575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600575.url(scheme.get, call_600575.host, call_600575.base,
                         call_600575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600575, url, valid)

proc call*(call_600576: Call_ListSchemaExtensions_600563; body: JsonNode): Recallable =
  ## listSchemaExtensions
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ##   body: JObject (required)
  var body_600577 = newJObject()
  if body != nil:
    body_600577 = body
  result = call_600576.call(nil, nil, nil, nil, body_600577)

var listSchemaExtensions* = Call_ListSchemaExtensions_600563(
    name: "listSchemaExtensions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListSchemaExtensions",
    validator: validate_ListSchemaExtensions_600564, base: "/",
    url: url_ListSchemaExtensions_600565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600578 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600580(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600579(path: JsonNode; query: JsonNode;
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
  var valid_600581 = header.getOrDefault("X-Amz-Date")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Date", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Security-Token")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Security-Token", valid_600582
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600583 = header.getOrDefault("X-Amz-Target")
  valid_600583 = validateParameter(valid_600583, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListTagsForResource"))
  if valid_600583 != nil:
    section.add "X-Amz-Target", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Content-Sha256", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Algorithm")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Algorithm", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Signature")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Signature", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-SignedHeaders", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Credential")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Credential", valid_600588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600590: Call_ListTagsForResource_600578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a directory.
  ## 
  let valid = call_600590.validator(path, query, header, formData, body)
  let scheme = call_600590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600590.url(scheme.get, call_600590.host, call_600590.base,
                         call_600590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600590, url, valid)

proc call*(call_600591: Call_ListTagsForResource_600578; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags on a directory.
  ##   body: JObject (required)
  var body_600592 = newJObject()
  if body != nil:
    body_600592 = body
  result = call_600591.call(nil, nil, nil, nil, body_600592)

var listTagsForResource* = Call_ListTagsForResource_600578(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListTagsForResource",
    validator: validate_ListTagsForResource_600579, base: "/",
    url: url_ListTagsForResource_600580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCertificate_600593 = ref object of OpenApiRestCall_599368
proc url_RegisterCertificate_600595(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterCertificate_600594(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600596 = header.getOrDefault("X-Amz-Date")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Date", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Security-Token")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Security-Token", valid_600597
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600598 = header.getOrDefault("X-Amz-Target")
  valid_600598 = validateParameter(valid_600598, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterCertificate"))
  if valid_600598 != nil:
    section.add "X-Amz-Target", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Content-Sha256", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Algorithm")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Algorithm", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Signature")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Signature", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-SignedHeaders", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Credential")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Credential", valid_600603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600605: Call_RegisterCertificate_600593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a certificate for secured LDAP connection.
  ## 
  let valid = call_600605.validator(path, query, header, formData, body)
  let scheme = call_600605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600605.url(scheme.get, call_600605.host, call_600605.base,
                         call_600605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600605, url, valid)

proc call*(call_600606: Call_RegisterCertificate_600593; body: JsonNode): Recallable =
  ## registerCertificate
  ## Registers a certificate for secured LDAP connection.
  ##   body: JObject (required)
  var body_600607 = newJObject()
  if body != nil:
    body_600607 = body
  result = call_600606.call(nil, nil, nil, nil, body_600607)

var registerCertificate* = Call_RegisterCertificate_600593(
    name: "registerCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterCertificate",
    validator: validate_RegisterCertificate_600594, base: "/",
    url: url_RegisterCertificate_600595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterEventTopic_600608 = ref object of OpenApiRestCall_599368
proc url_RegisterEventTopic_600610(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterEventTopic_600609(path: JsonNode; query: JsonNode;
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
  var valid_600611 = header.getOrDefault("X-Amz-Date")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Date", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Security-Token")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Security-Token", valid_600612
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600613 = header.getOrDefault("X-Amz-Target")
  valid_600613 = validateParameter(valid_600613, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterEventTopic"))
  if valid_600613 != nil:
    section.add "X-Amz-Target", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Content-Sha256", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-Algorithm")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Algorithm", valid_600615
  var valid_600616 = header.getOrDefault("X-Amz-Signature")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "X-Amz-Signature", valid_600616
  var valid_600617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-SignedHeaders", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Credential")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Credential", valid_600618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600620: Call_RegisterEventTopic_600608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ## 
  let valid = call_600620.validator(path, query, header, formData, body)
  let scheme = call_600620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600620.url(scheme.get, call_600620.host, call_600620.base,
                         call_600620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600620, url, valid)

proc call*(call_600621: Call_RegisterEventTopic_600608; body: JsonNode): Recallable =
  ## registerEventTopic
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ##   body: JObject (required)
  var body_600622 = newJObject()
  if body != nil:
    body_600622 = body
  result = call_600621.call(nil, nil, nil, nil, body_600622)

var registerEventTopic* = Call_RegisterEventTopic_600608(
    name: "registerEventTopic", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterEventTopic",
    validator: validate_RegisterEventTopic_600609, base: "/",
    url: url_RegisterEventTopic_600610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSharedDirectory_600623 = ref object of OpenApiRestCall_599368
proc url_RejectSharedDirectory_600625(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectSharedDirectory_600624(path: JsonNode; query: JsonNode;
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
  var valid_600626 = header.getOrDefault("X-Amz-Date")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Date", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Security-Token")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Security-Token", valid_600627
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600628 = header.getOrDefault("X-Amz-Target")
  valid_600628 = validateParameter(valid_600628, JString, required = true, default = newJString(
      "DirectoryService_20150416.RejectSharedDirectory"))
  if valid_600628 != nil:
    section.add "X-Amz-Target", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Content-Sha256", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Algorithm")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Algorithm", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-Signature")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-Signature", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-SignedHeaders", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Credential")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Credential", valid_600633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600635: Call_RejectSharedDirectory_600623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_600635.validator(path, query, header, formData, body)
  let scheme = call_600635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600635.url(scheme.get, call_600635.host, call_600635.base,
                         call_600635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600635, url, valid)

proc call*(call_600636: Call_RejectSharedDirectory_600623; body: JsonNode): Recallable =
  ## rejectSharedDirectory
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_600637 = newJObject()
  if body != nil:
    body_600637 = body
  result = call_600636.call(nil, nil, nil, nil, body_600637)

var rejectSharedDirectory* = Call_RejectSharedDirectory_600623(
    name: "rejectSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RejectSharedDirectory",
    validator: validate_RejectSharedDirectory_600624, base: "/",
    url: url_RejectSharedDirectory_600625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveIpRoutes_600638 = ref object of OpenApiRestCall_599368
proc url_RemoveIpRoutes_600640(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveIpRoutes_600639(path: JsonNode; query: JsonNode;
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
  var valid_600641 = header.getOrDefault("X-Amz-Date")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Date", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Security-Token")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Security-Token", valid_600642
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600643 = header.getOrDefault("X-Amz-Target")
  valid_600643 = validateParameter(valid_600643, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveIpRoutes"))
  if valid_600643 != nil:
    section.add "X-Amz-Target", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Content-Sha256", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Algorithm")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Algorithm", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-Signature")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-Signature", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-SignedHeaders", valid_600647
  var valid_600648 = header.getOrDefault("X-Amz-Credential")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Credential", valid_600648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600650: Call_RemoveIpRoutes_600638; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes IP address blocks from a directory.
  ## 
  let valid = call_600650.validator(path, query, header, formData, body)
  let scheme = call_600650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600650.url(scheme.get, call_600650.host, call_600650.base,
                         call_600650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600650, url, valid)

proc call*(call_600651: Call_RemoveIpRoutes_600638; body: JsonNode): Recallable =
  ## removeIpRoutes
  ## Removes IP address blocks from a directory.
  ##   body: JObject (required)
  var body_600652 = newJObject()
  if body != nil:
    body_600652 = body
  result = call_600651.call(nil, nil, nil, nil, body_600652)

var removeIpRoutes* = Call_RemoveIpRoutes_600638(name: "removeIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveIpRoutes",
    validator: validate_RemoveIpRoutes_600639, base: "/", url: url_RemoveIpRoutes_600640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_600653 = ref object of OpenApiRestCall_599368
proc url_RemoveTagsFromResource_600655(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_600654(path: JsonNode; query: JsonNode;
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
  var valid_600656 = header.getOrDefault("X-Amz-Date")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Date", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Security-Token")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Security-Token", valid_600657
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600658 = header.getOrDefault("X-Amz-Target")
  valid_600658 = validateParameter(valid_600658, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveTagsFromResource"))
  if valid_600658 != nil:
    section.add "X-Amz-Target", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Content-Sha256", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Algorithm")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Algorithm", valid_600660
  var valid_600661 = header.getOrDefault("X-Amz-Signature")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "X-Amz-Signature", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-SignedHeaders", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Credential")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Credential", valid_600663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600665: Call_RemoveTagsFromResource_600653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a directory.
  ## 
  let valid = call_600665.validator(path, query, header, formData, body)
  let scheme = call_600665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600665.url(scheme.get, call_600665.host, call_600665.base,
                         call_600665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600665, url, valid)

proc call*(call_600666: Call_RemoveTagsFromResource_600653; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tags from a directory.
  ##   body: JObject (required)
  var body_600667 = newJObject()
  if body != nil:
    body_600667 = body
  result = call_600666.call(nil, nil, nil, nil, body_600667)

var removeTagsFromResource* = Call_RemoveTagsFromResource_600653(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_600654, base: "/",
    url: url_RemoveTagsFromResource_600655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetUserPassword_600668 = ref object of OpenApiRestCall_599368
proc url_ResetUserPassword_600670(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetUserPassword_600669(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600671 = header.getOrDefault("X-Amz-Date")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Date", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Security-Token")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Security-Token", valid_600672
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600673 = header.getOrDefault("X-Amz-Target")
  valid_600673 = validateParameter(valid_600673, JString, required = true, default = newJString(
      "DirectoryService_20150416.ResetUserPassword"))
  if valid_600673 != nil:
    section.add "X-Amz-Target", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Content-Sha256", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Algorithm")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Algorithm", valid_600675
  var valid_600676 = header.getOrDefault("X-Amz-Signature")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Signature", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-SignedHeaders", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Credential")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Credential", valid_600678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600680: Call_ResetUserPassword_600668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_600680.validator(path, query, header, formData, body)
  let scheme = call_600680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600680.url(scheme.get, call_600680.host, call_600680.base,
                         call_600680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600680, url, valid)

proc call*(call_600681: Call_ResetUserPassword_600668; body: JsonNode): Recallable =
  ## resetUserPassword
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600682 = newJObject()
  if body != nil:
    body_600682 = body
  result = call_600681.call(nil, nil, nil, nil, body_600682)

var resetUserPassword* = Call_ResetUserPassword_600668(name: "resetUserPassword",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ResetUserPassword",
    validator: validate_ResetUserPassword_600669, base: "/",
    url: url_ResetUserPassword_600670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreFromSnapshot_600683 = ref object of OpenApiRestCall_599368
proc url_RestoreFromSnapshot_600685(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreFromSnapshot_600684(path: JsonNode; query: JsonNode;
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
  var valid_600686 = header.getOrDefault("X-Amz-Date")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Date", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Security-Token")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Security-Token", valid_600687
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600688 = header.getOrDefault("X-Amz-Target")
  valid_600688 = validateParameter(valid_600688, JString, required = true, default = newJString(
      "DirectoryService_20150416.RestoreFromSnapshot"))
  if valid_600688 != nil:
    section.add "X-Amz-Target", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Content-Sha256", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Algorithm")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Algorithm", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-Signature")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Signature", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-SignedHeaders", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Credential")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Credential", valid_600693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600695: Call_RestoreFromSnapshot_600683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ## 
  let valid = call_600695.validator(path, query, header, formData, body)
  let scheme = call_600695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600695.url(scheme.get, call_600695.host, call_600695.base,
                         call_600695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600695, url, valid)

proc call*(call_600696: Call_RestoreFromSnapshot_600683; body: JsonNode): Recallable =
  ## restoreFromSnapshot
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ##   body: JObject (required)
  var body_600697 = newJObject()
  if body != nil:
    body_600697 = body
  result = call_600696.call(nil, nil, nil, nil, body_600697)

var restoreFromSnapshot* = Call_RestoreFromSnapshot_600683(
    name: "restoreFromSnapshot", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RestoreFromSnapshot",
    validator: validate_RestoreFromSnapshot_600684, base: "/",
    url: url_RestoreFromSnapshot_600685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShareDirectory_600698 = ref object of OpenApiRestCall_599368
proc url_ShareDirectory_600700(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ShareDirectory_600699(path: JsonNode; query: JsonNode;
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
  var valid_600701 = header.getOrDefault("X-Amz-Date")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Date", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Security-Token")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Security-Token", valid_600702
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600703 = header.getOrDefault("X-Amz-Target")
  valid_600703 = validateParameter(valid_600703, JString, required = true, default = newJString(
      "DirectoryService_20150416.ShareDirectory"))
  if valid_600703 != nil:
    section.add "X-Amz-Target", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Content-Sha256", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Algorithm")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Algorithm", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-Signature")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Signature", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-SignedHeaders", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Credential")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Credential", valid_600708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600710: Call_ShareDirectory_600698; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ## 
  let valid = call_600710.validator(path, query, header, formData, body)
  let scheme = call_600710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600710.url(scheme.get, call_600710.host, call_600710.base,
                         call_600710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600710, url, valid)

proc call*(call_600711: Call_ShareDirectory_600698; body: JsonNode): Recallable =
  ## shareDirectory
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ##   body: JObject (required)
  var body_600712 = newJObject()
  if body != nil:
    body_600712 = body
  result = call_600711.call(nil, nil, nil, nil, body_600712)

var shareDirectory* = Call_ShareDirectory_600698(name: "shareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ShareDirectory",
    validator: validate_ShareDirectory_600699, base: "/", url: url_ShareDirectory_600700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaExtension_600713 = ref object of OpenApiRestCall_599368
proc url_StartSchemaExtension_600715(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSchemaExtension_600714(path: JsonNode; query: JsonNode;
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
  var valid_600716 = header.getOrDefault("X-Amz-Date")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Date", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Security-Token")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Security-Token", valid_600717
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600718 = header.getOrDefault("X-Amz-Target")
  valid_600718 = validateParameter(valid_600718, JString, required = true, default = newJString(
      "DirectoryService_20150416.StartSchemaExtension"))
  if valid_600718 != nil:
    section.add "X-Amz-Target", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Content-Sha256", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Algorithm")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Algorithm", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Signature")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Signature", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-SignedHeaders", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Credential")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Credential", valid_600723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600725: Call_StartSchemaExtension_600713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a schema extension to a Microsoft AD directory.
  ## 
  let valid = call_600725.validator(path, query, header, formData, body)
  let scheme = call_600725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600725.url(scheme.get, call_600725.host, call_600725.base,
                         call_600725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600725, url, valid)

proc call*(call_600726: Call_StartSchemaExtension_600713; body: JsonNode): Recallable =
  ## startSchemaExtension
  ## Applies a schema extension to a Microsoft AD directory.
  ##   body: JObject (required)
  var body_600727 = newJObject()
  if body != nil:
    body_600727 = body
  result = call_600726.call(nil, nil, nil, nil, body_600727)

var startSchemaExtension* = Call_StartSchemaExtension_600713(
    name: "startSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.StartSchemaExtension",
    validator: validate_StartSchemaExtension_600714, base: "/",
    url: url_StartSchemaExtension_600715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnshareDirectory_600728 = ref object of OpenApiRestCall_599368
proc url_UnshareDirectory_600730(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnshareDirectory_600729(path: JsonNode; query: JsonNode;
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
  var valid_600731 = header.getOrDefault("X-Amz-Date")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Date", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-Security-Token")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Security-Token", valid_600732
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600733 = header.getOrDefault("X-Amz-Target")
  valid_600733 = validateParameter(valid_600733, JString, required = true, default = newJString(
      "DirectoryService_20150416.UnshareDirectory"))
  if valid_600733 != nil:
    section.add "X-Amz-Target", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Content-Sha256", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Algorithm")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Algorithm", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Signature")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Signature", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-SignedHeaders", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Credential")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Credential", valid_600738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600740: Call_UnshareDirectory_600728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ## 
  let valid = call_600740.validator(path, query, header, formData, body)
  let scheme = call_600740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600740.url(scheme.get, call_600740.host, call_600740.base,
                         call_600740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600740, url, valid)

proc call*(call_600741: Call_UnshareDirectory_600728; body: JsonNode): Recallable =
  ## unshareDirectory
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ##   body: JObject (required)
  var body_600742 = newJObject()
  if body != nil:
    body_600742 = body
  result = call_600741.call(nil, nil, nil, nil, body_600742)

var unshareDirectory* = Call_UnshareDirectory_600728(name: "unshareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UnshareDirectory",
    validator: validate_UnshareDirectory_600729, base: "/",
    url: url_UnshareDirectory_600730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConditionalForwarder_600743 = ref object of OpenApiRestCall_599368
proc url_UpdateConditionalForwarder_600745(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConditionalForwarder_600744(path: JsonNode; query: JsonNode;
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
  var valid_600746 = header.getOrDefault("X-Amz-Date")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Date", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Security-Token")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Security-Token", valid_600747
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600748 = header.getOrDefault("X-Amz-Target")
  valid_600748 = validateParameter(valid_600748, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateConditionalForwarder"))
  if valid_600748 != nil:
    section.add "X-Amz-Target", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Content-Sha256", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Algorithm")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Algorithm", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Signature")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Signature", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-SignedHeaders", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Credential")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Credential", valid_600753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600755: Call_UpdateConditionalForwarder_600743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_600755.validator(path, query, header, formData, body)
  let scheme = call_600755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600755.url(scheme.get, call_600755.host, call_600755.base,
                         call_600755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600755, url, valid)

proc call*(call_600756: Call_UpdateConditionalForwarder_600743; body: JsonNode): Recallable =
  ## updateConditionalForwarder
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_600757 = newJObject()
  if body != nil:
    body_600757 = body
  result = call_600756.call(nil, nil, nil, nil, body_600757)

var updateConditionalForwarder* = Call_UpdateConditionalForwarder_600743(
    name: "updateConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateConditionalForwarder",
    validator: validate_UpdateConditionalForwarder_600744, base: "/",
    url: url_UpdateConditionalForwarder_600745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNumberOfDomainControllers_600758 = ref object of OpenApiRestCall_599368
proc url_UpdateNumberOfDomainControllers_600760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNumberOfDomainControllers_600759(path: JsonNode;
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
  var valid_600761 = header.getOrDefault("X-Amz-Date")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Date", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Security-Token")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Security-Token", valid_600762
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600763 = header.getOrDefault("X-Amz-Target")
  valid_600763 = validateParameter(valid_600763, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateNumberOfDomainControllers"))
  if valid_600763 != nil:
    section.add "X-Amz-Target", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Content-Sha256", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Algorithm")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Algorithm", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Signature")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Signature", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-SignedHeaders", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Credential")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Credential", valid_600768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600770: Call_UpdateNumberOfDomainControllers_600758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ## 
  let valid = call_600770.validator(path, query, header, formData, body)
  let scheme = call_600770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600770.url(scheme.get, call_600770.host, call_600770.base,
                         call_600770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600770, url, valid)

proc call*(call_600771: Call_UpdateNumberOfDomainControllers_600758; body: JsonNode): Recallable =
  ## updateNumberOfDomainControllers
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ##   body: JObject (required)
  var body_600772 = newJObject()
  if body != nil:
    body_600772 = body
  result = call_600771.call(nil, nil, nil, nil, body_600772)

var updateNumberOfDomainControllers* = Call_UpdateNumberOfDomainControllers_600758(
    name: "updateNumberOfDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateNumberOfDomainControllers",
    validator: validate_UpdateNumberOfDomainControllers_600759, base: "/",
    url: url_UpdateNumberOfDomainControllers_600760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRadius_600773 = ref object of OpenApiRestCall_599368
proc url_UpdateRadius_600775(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRadius_600774(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600776 = header.getOrDefault("X-Amz-Date")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Date", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Security-Token")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Security-Token", valid_600777
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600778 = header.getOrDefault("X-Amz-Target")
  valid_600778 = validateParameter(valid_600778, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateRadius"))
  if valid_600778 != nil:
    section.add "X-Amz-Target", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Content-Sha256", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Algorithm")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Algorithm", valid_600780
  var valid_600781 = header.getOrDefault("X-Amz-Signature")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-Signature", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-SignedHeaders", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-Credential")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Credential", valid_600783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600785: Call_UpdateRadius_600773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_600785.validator(path, query, header, formData, body)
  let scheme = call_600785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600785.url(scheme.get, call_600785.host, call_600785.base,
                         call_600785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600785, url, valid)

proc call*(call_600786: Call_UpdateRadius_600773; body: JsonNode): Recallable =
  ## updateRadius
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_600787 = newJObject()
  if body != nil:
    body_600787 = body
  result = call_600786.call(nil, nil, nil, nil, body_600787)

var updateRadius* = Call_UpdateRadius_600773(name: "updateRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UpdateRadius",
    validator: validate_UpdateRadius_600774, base: "/", url: url_UpdateRadius_600775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrust_600788 = ref object of OpenApiRestCall_599368
proc url_UpdateTrust_600790(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrust_600789(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600791 = header.getOrDefault("X-Amz-Date")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-Date", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-Security-Token")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Security-Token", valid_600792
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600793 = header.getOrDefault("X-Amz-Target")
  valid_600793 = validateParameter(valid_600793, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateTrust"))
  if valid_600793 != nil:
    section.add "X-Amz-Target", valid_600793
  var valid_600794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Content-Sha256", valid_600794
  var valid_600795 = header.getOrDefault("X-Amz-Algorithm")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "X-Amz-Algorithm", valid_600795
  var valid_600796 = header.getOrDefault("X-Amz-Signature")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Signature", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-SignedHeaders", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Credential")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Credential", valid_600798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600800: Call_UpdateTrust_600788; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ## 
  let valid = call_600800.validator(path, query, header, formData, body)
  let scheme = call_600800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600800.url(scheme.get, call_600800.host, call_600800.base,
                         call_600800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600800, url, valid)

proc call*(call_600801: Call_UpdateTrust_600788; body: JsonNode): Recallable =
  ## updateTrust
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ##   body: JObject (required)
  var body_600802 = newJObject()
  if body != nil:
    body_600802 = body
  result = call_600801.call(nil, nil, nil, nil, body_600802)

var updateTrust* = Call_UpdateTrust_600788(name: "updateTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateTrust",
                                        validator: validate_UpdateTrust_600789,
                                        base: "/", url: url_UpdateTrust_600790,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyTrust_600803 = ref object of OpenApiRestCall_599368
proc url_VerifyTrust_600805(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_VerifyTrust_600804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600806 = header.getOrDefault("X-Amz-Date")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Date", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-Security-Token")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-Security-Token", valid_600807
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600808 = header.getOrDefault("X-Amz-Target")
  valid_600808 = validateParameter(valid_600808, JString, required = true, default = newJString(
      "DirectoryService_20150416.VerifyTrust"))
  if valid_600808 != nil:
    section.add "X-Amz-Target", valid_600808
  var valid_600809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Content-Sha256", valid_600809
  var valid_600810 = header.getOrDefault("X-Amz-Algorithm")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Algorithm", valid_600810
  var valid_600811 = header.getOrDefault("X-Amz-Signature")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-Signature", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-SignedHeaders", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Credential")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Credential", valid_600813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600815: Call_VerifyTrust_600803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ## 
  let valid = call_600815.validator(path, query, header, formData, body)
  let scheme = call_600815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600815.url(scheme.get, call_600815.host, call_600815.base,
                         call_600815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600815, url, valid)

proc call*(call_600816: Call_VerifyTrust_600803; body: JsonNode): Recallable =
  ## verifyTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ##   body: JObject (required)
  var body_600817 = newJObject()
  if body != nil:
    body_600817 = body
  result = call_600816.call(nil, nil, nil, nil, body_600817)

var verifyTrust* = Call_VerifyTrust_600803(name: "verifyTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.VerifyTrust",
                                        validator: validate_VerifyTrust_600804,
                                        base: "/", url: url_VerifyTrust_600805,
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
