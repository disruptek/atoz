
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2016-11-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about the CloudFront API actions, data types, and errors. For detailed information about CloudFront features and their associated API calls, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20161125_601025 = ref object of OpenApiRestCall_600426
proc url_CreateCloudFrontOriginAccessIdentity20161125_601027(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCloudFrontOriginAccessIdentity20161125_601026(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
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
  var valid_601028 = header.getOrDefault("X-Amz-Date")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Date", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Security-Token")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Security-Token", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Content-Sha256", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Algorithm")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Algorithm", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Signature", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-SignedHeaders", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Credential")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Credential", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_CreateCloudFrontOriginAccessIdentity20161125_601025;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_CreateCloudFrontOriginAccessIdentity20161125_601025;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20161125
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_601038 = newJObject()
  if body != nil:
    body_601038 = body
  result = call_601037.call(nil, nil, nil, nil, body_601038)

var createCloudFrontOriginAccessIdentity20161125* = Call_CreateCloudFrontOriginAccessIdentity20161125_601025(
    name: "createCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20161125_601026,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20161125_601027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20161125_600768 = ref object of OpenApiRestCall_600426
proc url_ListCloudFrontOriginAccessIdentities20161125_600770(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCloudFrontOriginAccessIdentities20161125_600769(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_600882 = query.getOrDefault("Marker")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "Marker", valid_600882
  var valid_600883 = query.getOrDefault("MaxItems")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "MaxItems", valid_600883
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
  var valid_600884 = header.getOrDefault("X-Amz-Date")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Date", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Security-Token")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Security-Token", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Content-Sha256", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Algorithm")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Algorithm", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Signature")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Signature", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-SignedHeaders", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Credential")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Credential", valid_600890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_ListCloudFrontOriginAccessIdentities20161125_600768;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_ListCloudFrontOriginAccessIdentities20161125_600768;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20161125
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_600985 = newJObject()
  add(query_600985, "Marker", newJString(Marker))
  add(query_600985, "MaxItems", newJString(MaxItems))
  result = call_600984.call(nil, query_600985, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20161125* = Call_ListCloudFrontOriginAccessIdentities20161125_600768(
    name: "listCloudFrontOriginAccessIdentities20161125",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20161125_600769,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20161125_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20161125_601054 = ref object of OpenApiRestCall_600426
proc url_CreateDistribution20161125_601056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDistribution20161125_601055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
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
  var valid_601057 = header.getOrDefault("X-Amz-Date")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Date", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Security-Token")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Security-Token", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Content-Sha256", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Algorithm")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Algorithm", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Signature")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Signature", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-SignedHeaders", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Credential")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Credential", valid_601063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_CreateDistribution20161125_601054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"))
  result = hook(call_601065, url, valid)

proc call*(call_601066: Call_CreateDistribution20161125_601054; body: JsonNode): Recallable =
  ## createDistribution20161125
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ##   body: JObject (required)
  var body_601067 = newJObject()
  if body != nil:
    body_601067 = body
  result = call_601066.call(nil, nil, nil, nil, body_601067)

var createDistribution20161125* = Call_CreateDistribution20161125_601054(
    name: "createDistribution20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution",
    validator: validate_CreateDistribution20161125_601055, base: "/",
    url: url_CreateDistribution20161125_601056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20161125_601039 = ref object of OpenApiRestCall_600426
proc url_ListDistributions20161125_601041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDistributions20161125_601040(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_601042 = query.getOrDefault("Marker")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "Marker", valid_601042
  var valid_601043 = query.getOrDefault("MaxItems")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "MaxItems", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_ListDistributions20161125_601039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_ListDistributions20161125_601039; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20161125
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_601053 = newJObject()
  add(query_601053, "Marker", newJString(Marker))
  add(query_601053, "MaxItems", newJString(MaxItems))
  result = call_601052.call(nil, query_601053, nil, nil, nil)

var listDistributions20161125* = Call_ListDistributions20161125_601039(
    name: "listDistributions20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution",
    validator: validate_ListDistributions20161125_601040, base: "/",
    url: url_ListDistributions20161125_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20161125_601068 = ref object of OpenApiRestCall_600426
proc url_CreateDistributionWithTags20161125_601070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDistributionWithTags20161125_601069(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_601071 = query.getOrDefault("WithTags")
  valid_601071 = validateParameter(valid_601071, JBool, required = true, default = nil)
  if valid_601071 != nil:
    section.add "WithTags", valid_601071
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
  var valid_601072 = header.getOrDefault("X-Amz-Date")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Date", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Security-Token")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Security-Token", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Content-Sha256", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Algorithm")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Algorithm", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Signature")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Signature", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-SignedHeaders", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Credential")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Credential", valid_601078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_CreateDistributionWithTags20161125_601068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"))
  result = hook(call_601080, url, valid)

proc call*(call_601081: Call_CreateDistributionWithTags20161125_601068;
          WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20161125
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_601082 = newJObject()
  var body_601083 = newJObject()
  add(query_601082, "WithTags", newJBool(WithTags))
  if body != nil:
    body_601083 = body
  result = call_601081.call(nil, query_601082, nil, nil, body_601083)

var createDistributionWithTags20161125* = Call_CreateDistributionWithTags20161125_601068(
    name: "createDistributionWithTags20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20161125_601069, base: "/",
    url: url_CreateDistributionWithTags20161125_601070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20161125_601115 = ref object of OpenApiRestCall_600426
proc url_CreateInvalidation20161125_601117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateInvalidation20161125_601116(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_601118 = path.getOrDefault("DistributionId")
  valid_601118 = validateParameter(valid_601118, JString, required = true,
                                 default = nil)
  if valid_601118 != nil:
    section.add "DistributionId", valid_601118
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
  var valid_601119 = header.getOrDefault("X-Amz-Date")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Date", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Security-Token")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Security-Token", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Content-Sha256", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Algorithm")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Algorithm", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Signature")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Signature", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-SignedHeaders", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Credential")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Credential", valid_601125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601127: Call_CreateInvalidation20161125_601115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_601127.validator(path, query, header, formData, body)
  let scheme = call_601127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601127.url(scheme.get, call_601127.host, call_601127.base,
                         call_601127.route, valid.getOrDefault("path"))
  result = hook(call_601127, url, valid)

proc call*(call_601128: Call_CreateInvalidation20161125_601115; body: JsonNode;
          DistributionId: string): Recallable =
  ## createInvalidation20161125
  ## Create a new invalidation. 
  ##   body: JObject (required)
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  var path_601129 = newJObject()
  var body_601130 = newJObject()
  if body != nil:
    body_601130 = body
  add(path_601129, "DistributionId", newJString(DistributionId))
  result = call_601128.call(path_601129, nil, nil, nil, body_601130)

var createInvalidation20161125* = Call_CreateInvalidation20161125_601115(
    name: "createInvalidation20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20161125_601116, base: "/",
    url: url_CreateInvalidation20161125_601117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20161125_601084 = ref object of OpenApiRestCall_600426
proc url_ListInvalidations20161125_601086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListInvalidations20161125_601085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_601101 = path.getOrDefault("DistributionId")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "DistributionId", valid_601101
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_601102 = query.getOrDefault("Marker")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "Marker", valid_601102
  var valid_601103 = query.getOrDefault("MaxItems")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "MaxItems", valid_601103
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
  var valid_601104 = header.getOrDefault("X-Amz-Date")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Date", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Security-Token")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Security-Token", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Content-Sha256", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Algorithm")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Algorithm", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Signature")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Signature", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-SignedHeaders", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Credential")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Credential", valid_601110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_ListInvalidations20161125_601084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"))
  result = hook(call_601111, url, valid)

proc call*(call_601112: Call_ListInvalidations20161125_601084;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20161125
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_601113 = newJObject()
  var query_601114 = newJObject()
  add(query_601114, "Marker", newJString(Marker))
  add(query_601114, "MaxItems", newJString(MaxItems))
  add(path_601113, "DistributionId", newJString(DistributionId))
  result = call_601112.call(path_601113, query_601114, nil, nil, nil)

var listInvalidations20161125* = Call_ListInvalidations20161125_601084(
    name: "listInvalidations20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20161125_601085, base: "/",
    url: url_ListInvalidations20161125_601086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20161125_601146 = ref object of OpenApiRestCall_600426
proc url_CreateStreamingDistribution20161125_601148(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateStreamingDistribution20161125_601147(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
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
  var valid_601149 = header.getOrDefault("X-Amz-Date")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Date", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Security-Token")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Security-Token", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Content-Sha256", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Algorithm")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Algorithm", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Signature")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Signature", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-SignedHeaders", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Credential")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Credential", valid_601155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601157: Call_CreateStreamingDistribution20161125_601146;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_601157.validator(path, query, header, formData, body)
  let scheme = call_601157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601157.url(scheme.get, call_601157.host, call_601157.base,
                         call_601157.route, valid.getOrDefault("path"))
  result = hook(call_601157, url, valid)

proc call*(call_601158: Call_CreateStreamingDistribution20161125_601146;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20161125
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_601159 = newJObject()
  if body != nil:
    body_601159 = body
  result = call_601158.call(nil, nil, nil, nil, body_601159)

var createStreamingDistribution20161125* = Call_CreateStreamingDistribution20161125_601146(
    name: "createStreamingDistribution20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/streaming-distribution",
    validator: validate_CreateStreamingDistribution20161125_601147, base: "/",
    url: url_CreateStreamingDistribution20161125_601148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20161125_601131 = ref object of OpenApiRestCall_600426
proc url_ListStreamingDistributions20161125_601133(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListStreamingDistributions20161125_601132(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_601134 = query.getOrDefault("Marker")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "Marker", valid_601134
  var valid_601135 = query.getOrDefault("MaxItems")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "MaxItems", valid_601135
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

proc call*(call_601143: Call_ListStreamingDistributions20161125_601131;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_601143.validator(path, query, header, formData, body)
  let scheme = call_601143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601143.url(scheme.get, call_601143.host, call_601143.base,
                         call_601143.route, valid.getOrDefault("path"))
  result = hook(call_601143, url, valid)

proc call*(call_601144: Call_ListStreamingDistributions20161125_601131;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20161125
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_601145 = newJObject()
  add(query_601145, "Marker", newJString(Marker))
  add(query_601145, "MaxItems", newJString(MaxItems))
  result = call_601144.call(nil, query_601145, nil, nil, nil)

var listStreamingDistributions20161125* = Call_ListStreamingDistributions20161125_601131(
    name: "listStreamingDistributions20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/streaming-distribution",
    validator: validate_ListStreamingDistributions20161125_601132, base: "/",
    url: url_ListStreamingDistributions20161125_601133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20161125_601160 = ref object of OpenApiRestCall_600426
proc url_CreateStreamingDistributionWithTags20161125_601162(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateStreamingDistributionWithTags20161125_601161(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_601163 = query.getOrDefault("WithTags")
  valid_601163 = validateParameter(valid_601163, JBool, required = true, default = nil)
  if valid_601163 != nil:
    section.add "WithTags", valid_601163
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
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Content-Sha256", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Algorithm")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Algorithm", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Signature")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Signature", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-SignedHeaders", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Credential")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Credential", valid_601170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601172: Call_CreateStreamingDistributionWithTags20161125_601160;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_601172.validator(path, query, header, formData, body)
  let scheme = call_601172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601172.url(scheme.get, call_601172.host, call_601172.base,
                         call_601172.route, valid.getOrDefault("path"))
  result = hook(call_601172, url, valid)

proc call*(call_601173: Call_CreateStreamingDistributionWithTags20161125_601160;
          WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20161125
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_601174 = newJObject()
  var body_601175 = newJObject()
  add(query_601174, "WithTags", newJBool(WithTags))
  if body != nil:
    body_601175 = body
  result = call_601173.call(nil, query_601174, nil, nil, body_601175)

var createStreamingDistributionWithTags20161125* = Call_CreateStreamingDistributionWithTags20161125_601160(
    name: "createStreamingDistributionWithTags20161125",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20161125_601161,
    base: "/", url: url_CreateStreamingDistributionWithTags20161125_601162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20161125_601176 = ref object of OpenApiRestCall_600426
proc url_GetCloudFrontOriginAccessIdentity20161125_601178(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCloudFrontOriginAccessIdentity20161125_601177(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601179 = path.getOrDefault("Id")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "Id", valid_601179
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
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_GetCloudFrontOriginAccessIdentity20161125_601176;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"))
  result = hook(call_601187, url, valid)

proc call*(call_601188: Call_GetCloudFrontOriginAccessIdentity20161125_601176;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20161125
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_601189 = newJObject()
  add(path_601189, "Id", newJString(Id))
  result = call_601188.call(path_601189, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20161125* = Call_GetCloudFrontOriginAccessIdentity20161125_601176(
    name: "getCloudFrontOriginAccessIdentity20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20161125_601177,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20161125_601178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20161125_601190 = ref object of OpenApiRestCall_600426
proc url_DeleteCloudFrontOriginAccessIdentity20161125_601192(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteCloudFrontOriginAccessIdentity20161125_601191(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601193 = path.getOrDefault("Id")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = nil)
  if valid_601193 != nil:
    section.add "Id", valid_601193
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601194 = header.getOrDefault("X-Amz-Date")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Date", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Security-Token")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Security-Token", valid_601195
  var valid_601196 = header.getOrDefault("If-Match")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "If-Match", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Content-Sha256", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Algorithm")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Algorithm", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Signature")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Signature", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-SignedHeaders", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Credential")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Credential", valid_601201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601202: Call_DeleteCloudFrontOriginAccessIdentity20161125_601190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_601202.validator(path, query, header, formData, body)
  let scheme = call_601202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601202.url(scheme.get, call_601202.host, call_601202.base,
                         call_601202.route, valid.getOrDefault("path"))
  result = hook(call_601202, url, valid)

proc call*(call_601203: Call_DeleteCloudFrontOriginAccessIdentity20161125_601190;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20161125
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_601204 = newJObject()
  add(path_601204, "Id", newJString(Id))
  result = call_601203.call(path_601204, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20161125* = Call_DeleteCloudFrontOriginAccessIdentity20161125_601190(
    name: "deleteCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20161125_601191,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20161125_601192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20161125_601205 = ref object of OpenApiRestCall_600426
proc url_GetDistribution20161125_601207(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDistribution20161125_601206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601208 = path.getOrDefault("Id")
  valid_601208 = validateParameter(valid_601208, JString, required = true,
                                 default = nil)
  if valid_601208 != nil:
    section.add "Id", valid_601208
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
  var valid_601209 = header.getOrDefault("X-Amz-Date")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Date", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Security-Token")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Security-Token", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Content-Sha256", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Algorithm")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Algorithm", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Signature")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Signature", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-SignedHeaders", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Credential")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Credential", valid_601215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_GetDistribution20161125_601205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"))
  result = hook(call_601216, url, valid)

proc call*(call_601217: Call_GetDistribution20161125_601205; Id: string): Recallable =
  ## getDistribution20161125
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_601218 = newJObject()
  add(path_601218, "Id", newJString(Id))
  result = call_601217.call(path_601218, nil, nil, nil, nil)

var getDistribution20161125* = Call_GetDistribution20161125_601205(
    name: "getDistribution20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution/{Id}",
    validator: validate_GetDistribution20161125_601206, base: "/",
    url: url_GetDistribution20161125_601207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20161125_601219 = ref object of OpenApiRestCall_600426
proc url_DeleteDistribution20161125_601221(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDistribution20161125_601220(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601222 = path.getOrDefault("Id")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = nil)
  if valid_601222 != nil:
    section.add "Id", valid_601222
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601223 = header.getOrDefault("X-Amz-Date")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Date", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Security-Token")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Security-Token", valid_601224
  var valid_601225 = header.getOrDefault("If-Match")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "If-Match", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Content-Sha256", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Algorithm")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Algorithm", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Signature")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Signature", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-SignedHeaders", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Credential")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Credential", valid_601230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601231: Call_DeleteDistribution20161125_601219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_601231.validator(path, query, header, formData, body)
  let scheme = call_601231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601231.url(scheme.get, call_601231.host, call_601231.base,
                         call_601231.route, valid.getOrDefault("path"))
  result = hook(call_601231, url, valid)

proc call*(call_601232: Call_DeleteDistribution20161125_601219; Id: string): Recallable =
  ## deleteDistribution20161125
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_601233 = newJObject()
  add(path_601233, "Id", newJString(Id))
  result = call_601232.call(path_601233, nil, nil, nil, nil)

var deleteDistribution20161125* = Call_DeleteDistribution20161125_601219(
    name: "deleteDistribution20161125", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution/{Id}",
    validator: validate_DeleteDistribution20161125_601220, base: "/",
    url: url_DeleteDistribution20161125_601221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20161125_601234 = ref object of OpenApiRestCall_600426
proc url_GetStreamingDistribution20161125_601236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStreamingDistribution20161125_601235(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601237 = path.getOrDefault("Id")
  valid_601237 = validateParameter(valid_601237, JString, required = true,
                                 default = nil)
  if valid_601237 != nil:
    section.add "Id", valid_601237
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
  var valid_601238 = header.getOrDefault("X-Amz-Date")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Date", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Security-Token")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Security-Token", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Content-Sha256", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Algorithm")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Algorithm", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Signature")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Signature", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-SignedHeaders", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Credential")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Credential", valid_601244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601245: Call_GetStreamingDistribution20161125_601234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_601245.validator(path, query, header, formData, body)
  let scheme = call_601245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601245.url(scheme.get, call_601245.host, call_601245.base,
                         call_601245.route, valid.getOrDefault("path"))
  result = hook(call_601245, url, valid)

proc call*(call_601246: Call_GetStreamingDistribution20161125_601234; Id: string): Recallable =
  ## getStreamingDistribution20161125
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_601247 = newJObject()
  add(path_601247, "Id", newJString(Id))
  result = call_601246.call(path_601247, nil, nil, nil, nil)

var getStreamingDistribution20161125* = Call_GetStreamingDistribution20161125_601234(
    name: "getStreamingDistribution20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20161125_601235, base: "/",
    url: url_GetStreamingDistribution20161125_601236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20161125_601248 = ref object of OpenApiRestCall_600426
proc url_DeleteStreamingDistribution20161125_601250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteStreamingDistribution20161125_601249(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601251 = path.getOrDefault("Id")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = nil)
  if valid_601251 != nil:
    section.add "Id", valid_601251
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601252 = header.getOrDefault("X-Amz-Date")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Date", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Security-Token")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Security-Token", valid_601253
  var valid_601254 = header.getOrDefault("If-Match")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "If-Match", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Content-Sha256", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Algorithm")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Algorithm", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Signature")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Signature", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-SignedHeaders", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Credential")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Credential", valid_601259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601260: Call_DeleteStreamingDistribution20161125_601248;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_601260.validator(path, query, header, formData, body)
  let scheme = call_601260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601260.url(scheme.get, call_601260.host, call_601260.base,
                         call_601260.route, valid.getOrDefault("path"))
  result = hook(call_601260, url, valid)

proc call*(call_601261: Call_DeleteStreamingDistribution20161125_601248; Id: string): Recallable =
  ## deleteStreamingDistribution20161125
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_601262 = newJObject()
  add(path_601262, "Id", newJString(Id))
  result = call_601261.call(path_601262, nil, nil, nil, nil)

var deleteStreamingDistribution20161125* = Call_DeleteStreamingDistribution20161125_601248(
    name: "deleteStreamingDistribution20161125", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20161125_601249, base: "/",
    url: url_DeleteStreamingDistribution20161125_601250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20161125_601277 = ref object of OpenApiRestCall_600426
proc url_UpdateCloudFrontOriginAccessIdentity20161125_601279(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateCloudFrontOriginAccessIdentity20161125_601278(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601280 = path.getOrDefault("Id")
  valid_601280 = validateParameter(valid_601280, JString, required = true,
                                 default = nil)
  if valid_601280 != nil:
    section.add "Id", valid_601280
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601281 = header.getOrDefault("X-Amz-Date")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Date", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Security-Token")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Security-Token", valid_601282
  var valid_601283 = header.getOrDefault("If-Match")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "If-Match", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Content-Sha256", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Algorithm")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Algorithm", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Signature")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Signature", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-SignedHeaders", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Credential")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Credential", valid_601288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601290: Call_UpdateCloudFrontOriginAccessIdentity20161125_601277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_601290.validator(path, query, header, formData, body)
  let scheme = call_601290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601290.url(scheme.get, call_601290.host, call_601290.base,
                         call_601290.route, valid.getOrDefault("path"))
  result = hook(call_601290, url, valid)

proc call*(call_601291: Call_UpdateCloudFrontOriginAccessIdentity20161125_601277;
          Id: string; body: JsonNode): Recallable =
  ## updateCloudFrontOriginAccessIdentity20161125
  ## Update an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's id.
  ##   body: JObject (required)
  var path_601292 = newJObject()
  var body_601293 = newJObject()
  add(path_601292, "Id", newJString(Id))
  if body != nil:
    body_601293 = body
  result = call_601291.call(path_601292, nil, nil, nil, body_601293)

var updateCloudFrontOriginAccessIdentity20161125* = Call_UpdateCloudFrontOriginAccessIdentity20161125_601277(
    name: "updateCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20161125_601278,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20161125_601279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20161125_601263 = ref object of OpenApiRestCall_600426
proc url_GetCloudFrontOriginAccessIdentityConfig20161125_601265(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCloudFrontOriginAccessIdentityConfig20161125_601264(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601266 = path.getOrDefault("Id")
  valid_601266 = validateParameter(valid_601266, JString, required = true,
                                 default = nil)
  if valid_601266 != nil:
    section.add "Id", valid_601266
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
  var valid_601267 = header.getOrDefault("X-Amz-Date")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Date", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Security-Token")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Security-Token", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Content-Sha256", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Algorithm")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Algorithm", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Signature")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Signature", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-SignedHeaders", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Credential")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Credential", valid_601273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_GetCloudFrontOriginAccessIdentityConfig20161125_601263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_GetCloudFrontOriginAccessIdentityConfig20161125_601263;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20161125
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_601276 = newJObject()
  add(path_601276, "Id", newJString(Id))
  result = call_601275.call(path_601276, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20161125* = Call_GetCloudFrontOriginAccessIdentityConfig20161125_601263(
    name: "getCloudFrontOriginAccessIdentityConfig20161125",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20161125_601264,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20161125_601265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20161125_601308 = ref object of OpenApiRestCall_600426
proc url_UpdateDistribution20161125_601310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDistribution20161125_601309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601311 = path.getOrDefault("Id")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = nil)
  if valid_601311 != nil:
    section.add "Id", valid_601311
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601312 = header.getOrDefault("X-Amz-Date")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Date", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Security-Token")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Security-Token", valid_601313
  var valid_601314 = header.getOrDefault("If-Match")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "If-Match", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Content-Sha256", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Algorithm")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Algorithm", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Signature")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Signature", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-SignedHeaders", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Credential")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Credential", valid_601319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601321: Call_UpdateDistribution20161125_601308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a distribution. 
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"))
  result = hook(call_601321, url, valid)

proc call*(call_601322: Call_UpdateDistribution20161125_601308; Id: string;
          body: JsonNode): Recallable =
  ## updateDistribution20161125
  ## Update a distribution. 
  ##   Id: string (required)
  ##     : The distribution's id.
  ##   body: JObject (required)
  var path_601323 = newJObject()
  var body_601324 = newJObject()
  add(path_601323, "Id", newJString(Id))
  if body != nil:
    body_601324 = body
  result = call_601322.call(path_601323, nil, nil, nil, body_601324)

var updateDistribution20161125* = Call_UpdateDistribution20161125_601308(
    name: "updateDistribution20161125", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{Id}/config",
    validator: validate_UpdateDistribution20161125_601309, base: "/",
    url: url_UpdateDistribution20161125_601310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20161125_601294 = ref object of OpenApiRestCall_600426
proc url_GetDistributionConfig20161125_601296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDistributionConfig20161125_601295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601297 = path.getOrDefault("Id")
  valid_601297 = validateParameter(valid_601297, JString, required = true,
                                 default = nil)
  if valid_601297 != nil:
    section.add "Id", valid_601297
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
  var valid_601298 = header.getOrDefault("X-Amz-Date")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Date", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Security-Token")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Security-Token", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Content-Sha256", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Algorithm")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Algorithm", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Signature")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Signature", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-SignedHeaders", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Credential")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Credential", valid_601304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601305: Call_GetDistributionConfig20161125_601294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_601305.validator(path, query, header, formData, body)
  let scheme = call_601305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601305.url(scheme.get, call_601305.host, call_601305.base,
                         call_601305.route, valid.getOrDefault("path"))
  result = hook(call_601305, url, valid)

proc call*(call_601306: Call_GetDistributionConfig20161125_601294; Id: string): Recallable =
  ## getDistributionConfig20161125
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_601307 = newJObject()
  add(path_601307, "Id", newJString(Id))
  result = call_601306.call(path_601307, nil, nil, nil, nil)

var getDistributionConfig20161125* = Call_GetDistributionConfig20161125_601294(
    name: "getDistributionConfig20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20161125_601295, base: "/",
    url: url_GetDistributionConfig20161125_601296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20161125_601325 = ref object of OpenApiRestCall_600426
proc url_GetInvalidation20161125_601327(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetInvalidation20161125_601326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601328 = path.getOrDefault("Id")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "Id", valid_601328
  var valid_601329 = path.getOrDefault("DistributionId")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = nil)
  if valid_601329 != nil:
    section.add "DistributionId", valid_601329
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
  var valid_601330 = header.getOrDefault("X-Amz-Date")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Date", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Security-Token")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Security-Token", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Content-Sha256", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Algorithm")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Algorithm", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Signature")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Signature", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-SignedHeaders", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Credential")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Credential", valid_601336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601337: Call_GetInvalidation20161125_601325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_601337.validator(path, query, header, formData, body)
  let scheme = call_601337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601337.url(scheme.get, call_601337.host, call_601337.base,
                         call_601337.route, valid.getOrDefault("path"))
  result = hook(call_601337, url, valid)

proc call*(call_601338: Call_GetInvalidation20161125_601325; Id: string;
          DistributionId: string): Recallable =
  ## getInvalidation20161125
  ## Get the information about an invalidation. 
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_601339 = newJObject()
  add(path_601339, "Id", newJString(Id))
  add(path_601339, "DistributionId", newJString(DistributionId))
  result = call_601338.call(path_601339, nil, nil, nil, nil)

var getInvalidation20161125* = Call_GetInvalidation20161125_601325(
    name: "getInvalidation20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20161125_601326, base: "/",
    url: url_GetInvalidation20161125_601327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20161125_601354 = ref object of OpenApiRestCall_600426
proc url_UpdateStreamingDistribution20161125_601356(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateStreamingDistribution20161125_601355(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601357 = path.getOrDefault("Id")
  valid_601357 = validateParameter(valid_601357, JString, required = true,
                                 default = nil)
  if valid_601357 != nil:
    section.add "Id", valid_601357
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601358 = header.getOrDefault("X-Amz-Date")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Date", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Security-Token")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Security-Token", valid_601359
  var valid_601360 = header.getOrDefault("If-Match")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "If-Match", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Content-Sha256", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Algorithm")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Algorithm", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Signature")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Signature", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-SignedHeaders", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Credential")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Credential", valid_601365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601367: Call_UpdateStreamingDistribution20161125_601354;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_601367.validator(path, query, header, formData, body)
  let scheme = call_601367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601367.url(scheme.get, call_601367.host, call_601367.base,
                         call_601367.route, valid.getOrDefault("path"))
  result = hook(call_601367, url, valid)

proc call*(call_601368: Call_UpdateStreamingDistribution20161125_601354;
          Id: string; body: JsonNode): Recallable =
  ## updateStreamingDistribution20161125
  ## Update a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  ##   body: JObject (required)
  var path_601369 = newJObject()
  var body_601370 = newJObject()
  add(path_601369, "Id", newJString(Id))
  if body != nil:
    body_601370 = body
  result = call_601368.call(path_601369, nil, nil, nil, body_601370)

var updateStreamingDistribution20161125* = Call_UpdateStreamingDistribution20161125_601354(
    name: "updateStreamingDistribution20161125", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20161125_601355, base: "/",
    url: url_UpdateStreamingDistribution20161125_601356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20161125_601340 = ref object of OpenApiRestCall_600426
proc url_GetStreamingDistributionConfig20161125_601342(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStreamingDistributionConfig20161125_601341(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_601343 = path.getOrDefault("Id")
  valid_601343 = validateParameter(valid_601343, JString, required = true,
                                 default = nil)
  if valid_601343 != nil:
    section.add "Id", valid_601343
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
  var valid_601344 = header.getOrDefault("X-Amz-Date")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Date", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Security-Token")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Security-Token", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Content-Sha256", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Algorithm")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Algorithm", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Signature")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Signature", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-SignedHeaders", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Credential")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Credential", valid_601350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601351: Call_GetStreamingDistributionConfig20161125_601340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_601351.validator(path, query, header, formData, body)
  let scheme = call_601351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601351.url(scheme.get, call_601351.host, call_601351.base,
                         call_601351.route, valid.getOrDefault("path"))
  result = hook(call_601351, url, valid)

proc call*(call_601352: Call_GetStreamingDistributionConfig20161125_601340;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20161125
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_601353 = newJObject()
  add(path_601353, "Id", newJString(Id))
  result = call_601352.call(path_601353, nil, nil, nil, nil)

var getStreamingDistributionConfig20161125* = Call_GetStreamingDistributionConfig20161125_601340(
    name: "getStreamingDistributionConfig20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20161125_601341, base: "/",
    url: url_GetStreamingDistributionConfig20161125_601342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20161125_601371 = ref object of OpenApiRestCall_600426
proc url_ListDistributionsByWebACLId20161125_601373(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDistributionsByWebACLId20161125_601372(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_601374 = path.getOrDefault("WebACLId")
  valid_601374 = validateParameter(valid_601374, JString, required = true,
                                 default = nil)
  if valid_601374 != nil:
    section.add "WebACLId", valid_601374
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_601375 = query.getOrDefault("Marker")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "Marker", valid_601375
  var valid_601376 = query.getOrDefault("MaxItems")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "MaxItems", valid_601376
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
  var valid_601377 = header.getOrDefault("X-Amz-Date")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Date", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Security-Token")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Security-Token", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601384: Call_ListDistributionsByWebACLId20161125_601371;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_601384.validator(path, query, header, formData, body)
  let scheme = call_601384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601384.url(scheme.get, call_601384.host, call_601384.base,
                         call_601384.route, valid.getOrDefault("path"))
  result = hook(call_601384, url, valid)

proc call*(call_601385: Call_ListDistributionsByWebACLId20161125_601371;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20161125
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_601386 = newJObject()
  var query_601387 = newJObject()
  add(query_601387, "Marker", newJString(Marker))
  add(query_601387, "MaxItems", newJString(MaxItems))
  add(path_601386, "WebACLId", newJString(WebACLId))
  result = call_601385.call(path_601386, query_601387, nil, nil, nil)

var listDistributionsByWebACLId20161125* = Call_ListDistributionsByWebACLId20161125_601371(
    name: "listDistributionsByWebACLId20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20161125_601372, base: "/",
    url: url_ListDistributionsByWebACLId20161125_601373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20161125_601388 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource20161125_601390(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource20161125_601389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_601391 = query.getOrDefault("Resource")
  valid_601391 = validateParameter(valid_601391, JString, required = true,
                                 default = nil)
  if valid_601391 != nil:
    section.add "Resource", valid_601391
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
  var valid_601392 = header.getOrDefault("X-Amz-Date")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Date", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Security-Token")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Security-Token", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Content-Sha256", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Algorithm")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Algorithm", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Signature")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Signature", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-SignedHeaders", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Credential")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Credential", valid_601398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601399: Call_ListTagsForResource20161125_601388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_601399.validator(path, query, header, formData, body)
  let scheme = call_601399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601399.url(scheme.get, call_601399.host, call_601399.base,
                         call_601399.route, valid.getOrDefault("path"))
  result = hook(call_601399, url, valid)

proc call*(call_601400: Call_ListTagsForResource20161125_601388; Resource: string): Recallable =
  ## listTagsForResource20161125
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_601401 = newJObject()
  add(query_601401, "Resource", newJString(Resource))
  result = call_601400.call(nil, query_601401, nil, nil, nil)

var listTagsForResource20161125* = Call_ListTagsForResource20161125_601388(
    name: "listTagsForResource20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/tagging#Resource",
    validator: validate_ListTagsForResource20161125_601389, base: "/",
    url: url_ListTagsForResource20161125_601390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20161125_601402 = ref object of OpenApiRestCall_600426
proc url_TagResource20161125_601404(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource20161125_601403(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_601405 = query.getOrDefault("Resource")
  valid_601405 = validateParameter(valid_601405, JString, required = true,
                                 default = nil)
  if valid_601405 != nil:
    section.add "Resource", valid_601405
  var valid_601419 = query.getOrDefault("Operation")
  valid_601419 = validateParameter(valid_601419, JString, required = true,
                                 default = newJString("Tag"))
  if valid_601419 != nil:
    section.add "Operation", valid_601419
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
  var valid_601420 = header.getOrDefault("X-Amz-Date")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Date", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Security-Token")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Security-Token", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Content-Sha256", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Algorithm")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Algorithm", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Signature")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Signature", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-SignedHeaders", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Credential")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Credential", valid_601426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601428: Call_TagResource20161125_601402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_601428.validator(path, query, header, formData, body)
  let scheme = call_601428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601428.url(scheme.get, call_601428.host, call_601428.base,
                         call_601428.route, valid.getOrDefault("path"))
  result = hook(call_601428, url, valid)

proc call*(call_601429: Call_TagResource20161125_601402; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20161125
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_601430 = newJObject()
  var body_601431 = newJObject()
  add(query_601430, "Resource", newJString(Resource))
  add(query_601430, "Operation", newJString(Operation))
  if body != nil:
    body_601431 = body
  result = call_601429.call(nil, query_601430, nil, nil, body_601431)

var tagResource20161125* = Call_TagResource20161125_601402(
    name: "tagResource20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20161125_601403, base: "/",
    url: url_TagResource20161125_601404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20161125_601432 = ref object of OpenApiRestCall_600426
proc url_UntagResource20161125_601434(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource20161125_601433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_601435 = query.getOrDefault("Resource")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = nil)
  if valid_601435 != nil:
    section.add "Resource", valid_601435
  var valid_601436 = query.getOrDefault("Operation")
  valid_601436 = validateParameter(valid_601436, JString, required = true,
                                 default = newJString("Untag"))
  if valid_601436 != nil:
    section.add "Operation", valid_601436
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
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Content-Sha256", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Algorithm")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Algorithm", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Signature")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Signature", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-SignedHeaders", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Credential")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Credential", valid_601443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601445: Call_UntagResource20161125_601432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"))
  result = hook(call_601445, url, valid)

proc call*(call_601446: Call_UntagResource20161125_601432; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20161125
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_601447 = newJObject()
  var body_601448 = newJObject()
  add(query_601447, "Resource", newJString(Resource))
  add(query_601447, "Operation", newJString(Operation))
  if body != nil:
    body_601448 = body
  result = call_601446.call(nil, query_601447, nil, nil, body_601448)

var untagResource20161125* = Call_UntagResource20161125_601432(
    name: "untagResource20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20161125_601433, base: "/",
    url: url_UntagResource20161125_601434, schemes: {Scheme.Https, Scheme.Http})
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
