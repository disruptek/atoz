
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20161125_613253 = ref object of OpenApiRestCall_612658
proc url_CreateCloudFrontOriginAccessIdentity20161125_613255(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20161125_613254(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613256 = header.getOrDefault("X-Amz-Signature")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Signature", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Content-Sha256", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Date")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Date", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Credential")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Credential", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Security-Token")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Security-Token", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Algorithm")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Algorithm", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-SignedHeaders", valid_613262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_CreateCloudFrontOriginAccessIdentity20161125_613253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_CreateCloudFrontOriginAccessIdentity20161125_613253;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20161125
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_613266 = newJObject()
  if body != nil:
    body_613266 = body
  result = call_613265.call(nil, nil, nil, nil, body_613266)

var createCloudFrontOriginAccessIdentity20161125* = Call_CreateCloudFrontOriginAccessIdentity20161125_613253(
    name: "createCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20161125_613254,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20161125_613255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20161125_612996 = ref object of OpenApiRestCall_612658
proc url_ListCloudFrontOriginAccessIdentities20161125_612998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20161125_612997(path: JsonNode;
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
  var valid_613110 = query.getOrDefault("Marker")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "Marker", valid_613110
  var valid_613111 = query.getOrDefault("MaxItems")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "MaxItems", valid_613111
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
  var valid_613112 = header.getOrDefault("X-Amz-Signature")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Signature", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Content-Sha256", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Date")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Date", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Credential")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Credential", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Security-Token")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Security-Token", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Algorithm")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Algorithm", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-SignedHeaders", valid_613118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_ListCloudFrontOriginAccessIdentities20161125_612996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_ListCloudFrontOriginAccessIdentities20161125_612996;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20161125
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_613213 = newJObject()
  add(query_613213, "Marker", newJString(Marker))
  add(query_613213, "MaxItems", newJString(MaxItems))
  result = call_613212.call(nil, query_613213, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20161125* = Call_ListCloudFrontOriginAccessIdentities20161125_612996(
    name: "listCloudFrontOriginAccessIdentities20161125",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20161125_612997,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20161125_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20161125_613282 = ref object of OpenApiRestCall_612658
proc url_CreateDistribution20161125_613284(protocol: Scheme; host: string;
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

proc validate_CreateDistribution20161125_613283(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_CreateDistribution20161125_613282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_CreateDistribution20161125_613282; body: JsonNode): Recallable =
  ## createDistribution20161125
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ##   body: JObject (required)
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  result = call_613294.call(nil, nil, nil, nil, body_613295)

var createDistribution20161125* = Call_CreateDistribution20161125_613282(
    name: "createDistribution20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution",
    validator: validate_CreateDistribution20161125_613283, base: "/",
    url: url_CreateDistribution20161125_613284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20161125_613267 = ref object of OpenApiRestCall_612658
proc url_ListDistributions20161125_613269(protocol: Scheme; host: string;
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

proc validate_ListDistributions20161125_613268(path: JsonNode; query: JsonNode;
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
  var valid_613270 = query.getOrDefault("Marker")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "Marker", valid_613270
  var valid_613271 = query.getOrDefault("MaxItems")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "MaxItems", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_ListDistributions20161125_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_ListDistributions20161125_613267; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20161125
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_613281 = newJObject()
  add(query_613281, "Marker", newJString(Marker))
  add(query_613281, "MaxItems", newJString(MaxItems))
  result = call_613280.call(nil, query_613281, nil, nil, nil)

var listDistributions20161125* = Call_ListDistributions20161125_613267(
    name: "listDistributions20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution",
    validator: validate_ListDistributions20161125_613268, base: "/",
    url: url_ListDistributions20161125_613269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20161125_613296 = ref object of OpenApiRestCall_612658
proc url_CreateDistributionWithTags20161125_613298(protocol: Scheme; host: string;
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

proc validate_CreateDistributionWithTags20161125_613297(path: JsonNode;
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
  var valid_613299 = query.getOrDefault("WithTags")
  valid_613299 = validateParameter(valid_613299, JBool, required = true, default = nil)
  if valid_613299 != nil:
    section.add "WithTags", valid_613299
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
  var valid_613300 = header.getOrDefault("X-Amz-Signature")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Signature", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Content-Sha256", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Date")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Date", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Credential")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Credential", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Security-Token")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Security-Token", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Algorithm")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Algorithm", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-SignedHeaders", valid_613306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613308: Call_CreateDistributionWithTags20161125_613296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_613308.validator(path, query, header, formData, body)
  let scheme = call_613308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613308.url(scheme.get, call_613308.host, call_613308.base,
                         call_613308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613308, url, valid)

proc call*(call_613309: Call_CreateDistributionWithTags20161125_613296;
          body: JsonNode; WithTags: bool): Recallable =
  ## createDistributionWithTags20161125
  ## Create a new distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_613310 = newJObject()
  var body_613311 = newJObject()
  if body != nil:
    body_613311 = body
  add(query_613310, "WithTags", newJBool(WithTags))
  result = call_613309.call(nil, query_613310, nil, nil, body_613311)

var createDistributionWithTags20161125* = Call_CreateDistributionWithTags20161125_613296(
    name: "createDistributionWithTags20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20161125_613297, base: "/",
    url: url_CreateDistributionWithTags20161125_613298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20161125_613343 = ref object of OpenApiRestCall_612658
proc url_CreateInvalidation20161125_613345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20161125_613344(path: JsonNode; query: JsonNode;
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
  var valid_613346 = path.getOrDefault("DistributionId")
  valid_613346 = validateParameter(valid_613346, JString, required = true,
                                 default = nil)
  if valid_613346 != nil:
    section.add "DistributionId", valid_613346
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
  var valid_613347 = header.getOrDefault("X-Amz-Signature")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Signature", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Content-Sha256", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Date")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Date", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Credential")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Credential", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Security-Token")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Security-Token", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Algorithm")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Algorithm", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-SignedHeaders", valid_613353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613355: Call_CreateInvalidation20161125_613343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_613355.validator(path, query, header, formData, body)
  let scheme = call_613355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613355.url(scheme.get, call_613355.host, call_613355.base,
                         call_613355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613355, url, valid)

proc call*(call_613356: Call_CreateInvalidation20161125_613343;
          DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20161125
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  ##   body: JObject (required)
  var path_613357 = newJObject()
  var body_613358 = newJObject()
  add(path_613357, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_613358 = body
  result = call_613356.call(path_613357, nil, nil, nil, body_613358)

var createInvalidation20161125* = Call_CreateInvalidation20161125_613343(
    name: "createInvalidation20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20161125_613344, base: "/",
    url: url_CreateInvalidation20161125_613345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20161125_613312 = ref object of OpenApiRestCall_612658
proc url_ListInvalidations20161125_613314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20161125_613313(path: JsonNode; query: JsonNode;
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
  var valid_613329 = path.getOrDefault("DistributionId")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = nil)
  if valid_613329 != nil:
    section.add "DistributionId", valid_613329
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_613330 = query.getOrDefault("Marker")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "Marker", valid_613330
  var valid_613331 = query.getOrDefault("MaxItems")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "MaxItems", valid_613331
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
  var valid_613332 = header.getOrDefault("X-Amz-Signature")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Signature", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Content-Sha256", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Date")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Date", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Credential")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Credential", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Security-Token")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Security-Token", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Algorithm")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Algorithm", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-SignedHeaders", valid_613338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_ListInvalidations20161125_613312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_ListInvalidations20161125_613312;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20161125
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_613341 = newJObject()
  var query_613342 = newJObject()
  add(query_613342, "Marker", newJString(Marker))
  add(query_613342, "MaxItems", newJString(MaxItems))
  add(path_613341, "DistributionId", newJString(DistributionId))
  result = call_613340.call(path_613341, query_613342, nil, nil, nil)

var listInvalidations20161125* = Call_ListInvalidations20161125_613312(
    name: "listInvalidations20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20161125_613313, base: "/",
    url: url_ListInvalidations20161125_613314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20161125_613374 = ref object of OpenApiRestCall_612658
proc url_CreateStreamingDistribution20161125_613376(protocol: Scheme; host: string;
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

proc validate_CreateStreamingDistribution20161125_613375(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613377 = header.getOrDefault("X-Amz-Signature")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Signature", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Content-Sha256", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Date")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Date", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Credential")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Credential", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Security-Token")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Security-Token", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Algorithm")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Algorithm", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-SignedHeaders", valid_613383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613385: Call_CreateStreamingDistribution20161125_613374;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_613385.validator(path, query, header, formData, body)
  let scheme = call_613385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613385.url(scheme.get, call_613385.host, call_613385.base,
                         call_613385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613385, url, valid)

proc call*(call_613386: Call_CreateStreamingDistribution20161125_613374;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20161125
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_613387 = newJObject()
  if body != nil:
    body_613387 = body
  result = call_613386.call(nil, nil, nil, nil, body_613387)

var createStreamingDistribution20161125* = Call_CreateStreamingDistribution20161125_613374(
    name: "createStreamingDistribution20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/streaming-distribution",
    validator: validate_CreateStreamingDistribution20161125_613375, base: "/",
    url: url_CreateStreamingDistribution20161125_613376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20161125_613359 = ref object of OpenApiRestCall_612658
proc url_ListStreamingDistributions20161125_613361(protocol: Scheme; host: string;
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

proc validate_ListStreamingDistributions20161125_613360(path: JsonNode;
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
  var valid_613362 = query.getOrDefault("Marker")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "Marker", valid_613362
  var valid_613363 = query.getOrDefault("MaxItems")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "MaxItems", valid_613363
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
  var valid_613364 = header.getOrDefault("X-Amz-Signature")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Signature", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Content-Sha256", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Date")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Date", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Credential")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Credential", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Security-Token")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Security-Token", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Algorithm")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Algorithm", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-SignedHeaders", valid_613370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613371: Call_ListStreamingDistributions20161125_613359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_613371.validator(path, query, header, formData, body)
  let scheme = call_613371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613371.url(scheme.get, call_613371.host, call_613371.base,
                         call_613371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613371, url, valid)

proc call*(call_613372: Call_ListStreamingDistributions20161125_613359;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20161125
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_613373 = newJObject()
  add(query_613373, "Marker", newJString(Marker))
  add(query_613373, "MaxItems", newJString(MaxItems))
  result = call_613372.call(nil, query_613373, nil, nil, nil)

var listStreamingDistributions20161125* = Call_ListStreamingDistributions20161125_613359(
    name: "listStreamingDistributions20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/streaming-distribution",
    validator: validate_ListStreamingDistributions20161125_613360, base: "/",
    url: url_ListStreamingDistributions20161125_613361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20161125_613388 = ref object of OpenApiRestCall_612658
proc url_CreateStreamingDistributionWithTags20161125_613390(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20161125_613389(path: JsonNode;
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
  var valid_613391 = query.getOrDefault("WithTags")
  valid_613391 = validateParameter(valid_613391, JBool, required = true, default = nil)
  if valid_613391 != nil:
    section.add "WithTags", valid_613391
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
  var valid_613392 = header.getOrDefault("X-Amz-Signature")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Signature", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Content-Sha256", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Date")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Date", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Credential")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Credential", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Security-Token")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Security-Token", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Algorithm")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Algorithm", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-SignedHeaders", valid_613398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613400: Call_CreateStreamingDistributionWithTags20161125_613388;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_613400.validator(path, query, header, formData, body)
  let scheme = call_613400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613400.url(scheme.get, call_613400.host, call_613400.base,
                         call_613400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613400, url, valid)

proc call*(call_613401: Call_CreateStreamingDistributionWithTags20161125_613388;
          body: JsonNode; WithTags: bool): Recallable =
  ## createStreamingDistributionWithTags20161125
  ## Create a new streaming distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_613402 = newJObject()
  var body_613403 = newJObject()
  if body != nil:
    body_613403 = body
  add(query_613402, "WithTags", newJBool(WithTags))
  result = call_613401.call(nil, query_613402, nil, nil, body_613403)

var createStreamingDistributionWithTags20161125* = Call_CreateStreamingDistributionWithTags20161125_613388(
    name: "createStreamingDistributionWithTags20161125",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20161125_613389,
    base: "/", url: url_CreateStreamingDistributionWithTags20161125_613390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20161125_613404 = ref object of OpenApiRestCall_612658
proc url_GetCloudFrontOriginAccessIdentity20161125_613406(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20161125_613405(path: JsonNode;
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
  var valid_613407 = path.getOrDefault("Id")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = nil)
  if valid_613407 != nil:
    section.add "Id", valid_613407
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
  var valid_613408 = header.getOrDefault("X-Amz-Signature")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Signature", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Content-Sha256", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Date")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Date", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Credential")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Credential", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Security-Token")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Security-Token", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Algorithm")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Algorithm", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-SignedHeaders", valid_613414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613415: Call_GetCloudFrontOriginAccessIdentity20161125_613404;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_613415.validator(path, query, header, formData, body)
  let scheme = call_613415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613415.url(scheme.get, call_613415.host, call_613415.base,
                         call_613415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613415, url, valid)

proc call*(call_613416: Call_GetCloudFrontOriginAccessIdentity20161125_613404;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20161125
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_613417 = newJObject()
  add(path_613417, "Id", newJString(Id))
  result = call_613416.call(path_613417, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20161125* = Call_GetCloudFrontOriginAccessIdentity20161125_613404(
    name: "getCloudFrontOriginAccessIdentity20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20161125_613405,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20161125_613406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20161125_613418 = ref object of OpenApiRestCall_612658
proc url_DeleteCloudFrontOriginAccessIdentity20161125_613420(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20161125_613419(path: JsonNode;
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
  var valid_613421 = path.getOrDefault("Id")
  valid_613421 = validateParameter(valid_613421, JString, required = true,
                                 default = nil)
  if valid_613421 != nil:
    section.add "Id", valid_613421
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613422 = header.getOrDefault("X-Amz-Signature")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Signature", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Content-Sha256", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Date")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Date", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Credential")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Credential", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Security-Token")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Security-Token", valid_613426
  var valid_613427 = header.getOrDefault("If-Match")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "If-Match", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Algorithm")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Algorithm", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-SignedHeaders", valid_613429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613430: Call_DeleteCloudFrontOriginAccessIdentity20161125_613418;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_613430.validator(path, query, header, formData, body)
  let scheme = call_613430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613430.url(scheme.get, call_613430.host, call_613430.base,
                         call_613430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613430, url, valid)

proc call*(call_613431: Call_DeleteCloudFrontOriginAccessIdentity20161125_613418;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20161125
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_613432 = newJObject()
  add(path_613432, "Id", newJString(Id))
  result = call_613431.call(path_613432, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20161125* = Call_DeleteCloudFrontOriginAccessIdentity20161125_613418(
    name: "deleteCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20161125_613419,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20161125_613420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20161125_613433 = ref object of OpenApiRestCall_612658
proc url_GetDistribution20161125_613435(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20161125_613434(path: JsonNode; query: JsonNode;
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
  var valid_613436 = path.getOrDefault("Id")
  valid_613436 = validateParameter(valid_613436, JString, required = true,
                                 default = nil)
  if valid_613436 != nil:
    section.add "Id", valid_613436
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
  var valid_613437 = header.getOrDefault("X-Amz-Signature")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Signature", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Content-Sha256", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Date")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Date", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Credential")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Credential", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Security-Token")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Security-Token", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Algorithm")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Algorithm", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-SignedHeaders", valid_613443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613444: Call_GetDistribution20161125_613433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_613444.validator(path, query, header, formData, body)
  let scheme = call_613444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613444.url(scheme.get, call_613444.host, call_613444.base,
                         call_613444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613444, url, valid)

proc call*(call_613445: Call_GetDistribution20161125_613433; Id: string): Recallable =
  ## getDistribution20161125
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_613446 = newJObject()
  add(path_613446, "Id", newJString(Id))
  result = call_613445.call(path_613446, nil, nil, nil, nil)

var getDistribution20161125* = Call_GetDistribution20161125_613433(
    name: "getDistribution20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution/{Id}",
    validator: validate_GetDistribution20161125_613434, base: "/",
    url: url_GetDistribution20161125_613435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20161125_613447 = ref object of OpenApiRestCall_612658
proc url_DeleteDistribution20161125_613449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20161125_613448(path: JsonNode; query: JsonNode;
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
  var valid_613450 = path.getOrDefault("Id")
  valid_613450 = validateParameter(valid_613450, JString, required = true,
                                 default = nil)
  if valid_613450 != nil:
    section.add "Id", valid_613450
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613451 = header.getOrDefault("X-Amz-Signature")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Signature", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Content-Sha256", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Date")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Date", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Credential")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Credential", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Security-Token")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Security-Token", valid_613455
  var valid_613456 = header.getOrDefault("If-Match")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "If-Match", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Algorithm")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Algorithm", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-SignedHeaders", valid_613458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613459: Call_DeleteDistribution20161125_613447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_613459.validator(path, query, header, formData, body)
  let scheme = call_613459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613459.url(scheme.get, call_613459.host, call_613459.base,
                         call_613459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613459, url, valid)

proc call*(call_613460: Call_DeleteDistribution20161125_613447; Id: string): Recallable =
  ## deleteDistribution20161125
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_613461 = newJObject()
  add(path_613461, "Id", newJString(Id))
  result = call_613460.call(path_613461, nil, nil, nil, nil)

var deleteDistribution20161125* = Call_DeleteDistribution20161125_613447(
    name: "deleteDistribution20161125", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution/{Id}",
    validator: validate_DeleteDistribution20161125_613448, base: "/",
    url: url_DeleteDistribution20161125_613449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20161125_613462 = ref object of OpenApiRestCall_612658
proc url_GetStreamingDistribution20161125_613464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20161125_613463(path: JsonNode;
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
  var valid_613465 = path.getOrDefault("Id")
  valid_613465 = validateParameter(valid_613465, JString, required = true,
                                 default = nil)
  if valid_613465 != nil:
    section.add "Id", valid_613465
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
  var valid_613466 = header.getOrDefault("X-Amz-Signature")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Signature", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Content-Sha256", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Date")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Date", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Credential")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Credential", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Security-Token")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Security-Token", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Algorithm")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Algorithm", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-SignedHeaders", valid_613472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613473: Call_GetStreamingDistribution20161125_613462;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_613473.validator(path, query, header, formData, body)
  let scheme = call_613473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613473.url(scheme.get, call_613473.host, call_613473.base,
                         call_613473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613473, url, valid)

proc call*(call_613474: Call_GetStreamingDistribution20161125_613462; Id: string): Recallable =
  ## getStreamingDistribution20161125
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_613475 = newJObject()
  add(path_613475, "Id", newJString(Id))
  result = call_613474.call(path_613475, nil, nil, nil, nil)

var getStreamingDistribution20161125* = Call_GetStreamingDistribution20161125_613462(
    name: "getStreamingDistribution20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20161125_613463, base: "/",
    url: url_GetStreamingDistribution20161125_613464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20161125_613476 = ref object of OpenApiRestCall_612658
proc url_DeleteStreamingDistribution20161125_613478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20161125_613477(path: JsonNode;
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
  var valid_613479 = path.getOrDefault("Id")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "Id", valid_613479
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("If-Match")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "If-Match", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_DeleteStreamingDistribution20161125_613476;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_DeleteStreamingDistribution20161125_613476; Id: string): Recallable =
  ## deleteStreamingDistribution20161125
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_613490 = newJObject()
  add(path_613490, "Id", newJString(Id))
  result = call_613489.call(path_613490, nil, nil, nil, nil)

var deleteStreamingDistribution20161125* = Call_DeleteStreamingDistribution20161125_613476(
    name: "deleteStreamingDistribution20161125", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20161125_613477, base: "/",
    url: url_DeleteStreamingDistribution20161125_613478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20161125_613505 = ref object of OpenApiRestCall_612658
proc url_UpdateCloudFrontOriginAccessIdentity20161125_613507(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20161125_613506(path: JsonNode;
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
  var valid_613508 = path.getOrDefault("Id")
  valid_613508 = validateParameter(valid_613508, JString, required = true,
                                 default = nil)
  if valid_613508 != nil:
    section.add "Id", valid_613508
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  var valid_613514 = header.getOrDefault("If-Match")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "If-Match", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Algorithm")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Algorithm", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-SignedHeaders", valid_613516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613518: Call_UpdateCloudFrontOriginAccessIdentity20161125_613505;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_613518.validator(path, query, header, formData, body)
  let scheme = call_613518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613518.url(scheme.get, call_613518.host, call_613518.base,
                         call_613518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613518, url, valid)

proc call*(call_613519: Call_UpdateCloudFrontOriginAccessIdentity20161125_613505;
          body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20161125
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identity's id.
  var path_613520 = newJObject()
  var body_613521 = newJObject()
  if body != nil:
    body_613521 = body
  add(path_613520, "Id", newJString(Id))
  result = call_613519.call(path_613520, nil, nil, nil, body_613521)

var updateCloudFrontOriginAccessIdentity20161125* = Call_UpdateCloudFrontOriginAccessIdentity20161125_613505(
    name: "updateCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20161125_613506,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20161125_613507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20161125_613491 = ref object of OpenApiRestCall_612658
proc url_GetCloudFrontOriginAccessIdentityConfig20161125_613493(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20161125_613492(
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
  var valid_613494 = path.getOrDefault("Id")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "Id", valid_613494
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
  var valid_613495 = header.getOrDefault("X-Amz-Signature")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Signature", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Content-Sha256", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Date")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Date", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Credential")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Credential", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Security-Token")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Security-Token", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Algorithm")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Algorithm", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-SignedHeaders", valid_613501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_GetCloudFrontOriginAccessIdentityConfig20161125_613491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_GetCloudFrontOriginAccessIdentityConfig20161125_613491;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20161125
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_613504 = newJObject()
  add(path_613504, "Id", newJString(Id))
  result = call_613503.call(path_613504, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20161125* = Call_GetCloudFrontOriginAccessIdentityConfig20161125_613491(
    name: "getCloudFrontOriginAccessIdentityConfig20161125",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20161125_613492,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20161125_613493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20161125_613536 = ref object of OpenApiRestCall_612658
proc url_UpdateDistribution20161125_613538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20161125_613537(path: JsonNode; query: JsonNode;
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
  var valid_613539 = path.getOrDefault("Id")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = nil)
  if valid_613539 != nil:
    section.add "Id", valid_613539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613540 = header.getOrDefault("X-Amz-Signature")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Signature", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Content-Sha256", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Date")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Date", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Credential")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Credential", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Security-Token")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Security-Token", valid_613544
  var valid_613545 = header.getOrDefault("If-Match")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "If-Match", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Algorithm")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Algorithm", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-SignedHeaders", valid_613547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_UpdateDistribution20161125_613536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a distribution. 
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_UpdateDistribution20161125_613536; body: JsonNode;
          Id: string): Recallable =
  ## updateDistribution20161125
  ## Update a distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The distribution's id.
  var path_613551 = newJObject()
  var body_613552 = newJObject()
  if body != nil:
    body_613552 = body
  add(path_613551, "Id", newJString(Id))
  result = call_613550.call(path_613551, nil, nil, nil, body_613552)

var updateDistribution20161125* = Call_UpdateDistribution20161125_613536(
    name: "updateDistribution20161125", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{Id}/config",
    validator: validate_UpdateDistribution20161125_613537, base: "/",
    url: url_UpdateDistribution20161125_613538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20161125_613522 = ref object of OpenApiRestCall_612658
proc url_GetDistributionConfig20161125_613524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20161125_613523(path: JsonNode; query: JsonNode;
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
  var valid_613525 = path.getOrDefault("Id")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = nil)
  if valid_613525 != nil:
    section.add "Id", valid_613525
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
  var valid_613526 = header.getOrDefault("X-Amz-Signature")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Signature", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Content-Sha256", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Date")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Date", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Credential")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Credential", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Security-Token")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Security-Token", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Algorithm")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Algorithm", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-SignedHeaders", valid_613532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613533: Call_GetDistributionConfig20161125_613522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_613533.validator(path, query, header, formData, body)
  let scheme = call_613533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613533.url(scheme.get, call_613533.host, call_613533.base,
                         call_613533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613533, url, valid)

proc call*(call_613534: Call_GetDistributionConfig20161125_613522; Id: string): Recallable =
  ## getDistributionConfig20161125
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_613535 = newJObject()
  add(path_613535, "Id", newJString(Id))
  result = call_613534.call(path_613535, nil, nil, nil, nil)

var getDistributionConfig20161125* = Call_GetDistributionConfig20161125_613522(
    name: "getDistributionConfig20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20161125_613523, base: "/",
    url: url_GetDistributionConfig20161125_613524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20161125_613553 = ref object of OpenApiRestCall_612658
proc url_GetInvalidation20161125_613555(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20161125_613554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_613556 = path.getOrDefault("DistributionId")
  valid_613556 = validateParameter(valid_613556, JString, required = true,
                                 default = nil)
  if valid_613556 != nil:
    section.add "DistributionId", valid_613556
  var valid_613557 = path.getOrDefault("Id")
  valid_613557 = validateParameter(valid_613557, JString, required = true,
                                 default = nil)
  if valid_613557 != nil:
    section.add "Id", valid_613557
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
  var valid_613558 = header.getOrDefault("X-Amz-Signature")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Signature", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Content-Sha256", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Date")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Date", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Credential")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Credential", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Security-Token")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Security-Token", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Algorithm")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Algorithm", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-SignedHeaders", valid_613564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613565: Call_GetInvalidation20161125_613553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_613565.validator(path, query, header, formData, body)
  let scheme = call_613565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613565.url(scheme.get, call_613565.host, call_613565.base,
                         call_613565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613565, url, valid)

proc call*(call_613566: Call_GetInvalidation20161125_613553;
          DistributionId: string; Id: string): Recallable =
  ## getInvalidation20161125
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  var path_613567 = newJObject()
  add(path_613567, "DistributionId", newJString(DistributionId))
  add(path_613567, "Id", newJString(Id))
  result = call_613566.call(path_613567, nil, nil, nil, nil)

var getInvalidation20161125* = Call_GetInvalidation20161125_613553(
    name: "getInvalidation20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20161125_613554, base: "/",
    url: url_GetInvalidation20161125_613555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20161125_613582 = ref object of OpenApiRestCall_612658
proc url_UpdateStreamingDistribution20161125_613584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20161125_613583(path: JsonNode;
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
  var valid_613585 = path.getOrDefault("Id")
  valid_613585 = validateParameter(valid_613585, JString, required = true,
                                 default = nil)
  if valid_613585 != nil:
    section.add "Id", valid_613585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613586 = header.getOrDefault("X-Amz-Signature")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Signature", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Content-Sha256", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Date")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Date", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Credential")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Credential", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Security-Token")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Security-Token", valid_613590
  var valid_613591 = header.getOrDefault("If-Match")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "If-Match", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Algorithm")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Algorithm", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-SignedHeaders", valid_613593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613595: Call_UpdateStreamingDistribution20161125_613582;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_613595.validator(path, query, header, formData, body)
  let scheme = call_613595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613595.url(scheme.get, call_613595.host, call_613595.base,
                         call_613595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613595, url, valid)

proc call*(call_613596: Call_UpdateStreamingDistribution20161125_613582;
          body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20161125
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  var path_613597 = newJObject()
  var body_613598 = newJObject()
  if body != nil:
    body_613598 = body
  add(path_613597, "Id", newJString(Id))
  result = call_613596.call(path_613597, nil, nil, nil, body_613598)

var updateStreamingDistribution20161125* = Call_UpdateStreamingDistribution20161125_613582(
    name: "updateStreamingDistribution20161125", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20161125_613583, base: "/",
    url: url_UpdateStreamingDistribution20161125_613584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20161125_613568 = ref object of OpenApiRestCall_612658
proc url_GetStreamingDistributionConfig20161125_613570(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20161125_613569(path: JsonNode;
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
  var valid_613571 = path.getOrDefault("Id")
  valid_613571 = validateParameter(valid_613571, JString, required = true,
                                 default = nil)
  if valid_613571 != nil:
    section.add "Id", valid_613571
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
  var valid_613572 = header.getOrDefault("X-Amz-Signature")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Signature", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Content-Sha256", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Date")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Date", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Credential")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Credential", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Security-Token")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Security-Token", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Algorithm")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Algorithm", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-SignedHeaders", valid_613578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613579: Call_GetStreamingDistributionConfig20161125_613568;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_613579.validator(path, query, header, formData, body)
  let scheme = call_613579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613579.url(scheme.get, call_613579.host, call_613579.base,
                         call_613579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613579, url, valid)

proc call*(call_613580: Call_GetStreamingDistributionConfig20161125_613568;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20161125
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_613581 = newJObject()
  add(path_613581, "Id", newJString(Id))
  result = call_613580.call(path_613581, nil, nil, nil, nil)

var getStreamingDistributionConfig20161125* = Call_GetStreamingDistributionConfig20161125_613568(
    name: "getStreamingDistributionConfig20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20161125_613569, base: "/",
    url: url_GetStreamingDistributionConfig20161125_613570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20161125_613599 = ref object of OpenApiRestCall_612658
proc url_ListDistributionsByWebACLId20161125_613601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20161125_613600(path: JsonNode;
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
  var valid_613602 = path.getOrDefault("WebACLId")
  valid_613602 = validateParameter(valid_613602, JString, required = true,
                                 default = nil)
  if valid_613602 != nil:
    section.add "WebACLId", valid_613602
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_613603 = query.getOrDefault("Marker")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "Marker", valid_613603
  var valid_613604 = query.getOrDefault("MaxItems")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "MaxItems", valid_613604
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
  var valid_613605 = header.getOrDefault("X-Amz-Signature")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Signature", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Content-Sha256", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Date")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Date", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Credential")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Credential", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Security-Token")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Security-Token", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Algorithm")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Algorithm", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-SignedHeaders", valid_613611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613612: Call_ListDistributionsByWebACLId20161125_613599;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_613612.validator(path, query, header, formData, body)
  let scheme = call_613612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613612.url(scheme.get, call_613612.host, call_613612.base,
                         call_613612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613612, url, valid)

proc call*(call_613613: Call_ListDistributionsByWebACLId20161125_613599;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20161125
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_613614 = newJObject()
  var query_613615 = newJObject()
  add(query_613615, "Marker", newJString(Marker))
  add(query_613615, "MaxItems", newJString(MaxItems))
  add(path_613614, "WebACLId", newJString(WebACLId))
  result = call_613613.call(path_613614, query_613615, nil, nil, nil)

var listDistributionsByWebACLId20161125* = Call_ListDistributionsByWebACLId20161125_613599(
    name: "listDistributionsByWebACLId20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20161125_613600, base: "/",
    url: url_ListDistributionsByWebACLId20161125_613601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20161125_613616 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource20161125_613618(protocol: Scheme; host: string;
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

proc validate_ListTagsForResource20161125_613617(path: JsonNode; query: JsonNode;
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
  var valid_613619 = query.getOrDefault("Resource")
  valid_613619 = validateParameter(valid_613619, JString, required = true,
                                 default = nil)
  if valid_613619 != nil:
    section.add "Resource", valid_613619
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
  var valid_613620 = header.getOrDefault("X-Amz-Signature")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Signature", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Content-Sha256", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Date")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Date", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Credential")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Credential", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Security-Token")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Security-Token", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Algorithm")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Algorithm", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-SignedHeaders", valid_613626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613627: Call_ListTagsForResource20161125_613616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_613627.validator(path, query, header, formData, body)
  let scheme = call_613627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613627.url(scheme.get, call_613627.host, call_613627.base,
                         call_613627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613627, url, valid)

proc call*(call_613628: Call_ListTagsForResource20161125_613616; Resource: string): Recallable =
  ## listTagsForResource20161125
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_613629 = newJObject()
  add(query_613629, "Resource", newJString(Resource))
  result = call_613628.call(nil, query_613629, nil, nil, nil)

var listTagsForResource20161125* = Call_ListTagsForResource20161125_613616(
    name: "listTagsForResource20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/tagging#Resource",
    validator: validate_ListTagsForResource20161125_613617, base: "/",
    url: url_ListTagsForResource20161125_613618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20161125_613630 = ref object of OpenApiRestCall_612658
proc url_TagResource20161125_613632(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource20161125_613631(path: JsonNode; query: JsonNode;
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
  var valid_613633 = query.getOrDefault("Resource")
  valid_613633 = validateParameter(valid_613633, JString, required = true,
                                 default = nil)
  if valid_613633 != nil:
    section.add "Resource", valid_613633
  var valid_613647 = query.getOrDefault("Operation")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = newJString("Tag"))
  if valid_613647 != nil:
    section.add "Operation", valid_613647
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

proc call*(call_613656: Call_TagResource20161125_613630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_613656.validator(path, query, header, formData, body)
  let scheme = call_613656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613656.url(scheme.get, call_613656.host, call_613656.base,
                         call_613656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613656, url, valid)

proc call*(call_613657: Call_TagResource20161125_613630; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20161125
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_613658 = newJObject()
  var body_613659 = newJObject()
  add(query_613658, "Resource", newJString(Resource))
  add(query_613658, "Operation", newJString(Operation))
  if body != nil:
    body_613659 = body
  result = call_613657.call(nil, query_613658, nil, nil, body_613659)

var tagResource20161125* = Call_TagResource20161125_613630(
    name: "tagResource20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20161125_613631, base: "/",
    url: url_TagResource20161125_613632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20161125_613660 = ref object of OpenApiRestCall_612658
proc url_UntagResource20161125_613662(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource20161125_613661(path: JsonNode; query: JsonNode;
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
  var valid_613663 = query.getOrDefault("Resource")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = nil)
  if valid_613663 != nil:
    section.add "Resource", valid_613663
  var valid_613664 = query.getOrDefault("Operation")
  valid_613664 = validateParameter(valid_613664, JString, required = true,
                                 default = newJString("Untag"))
  if valid_613664 != nil:
    section.add "Operation", valid_613664
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
  var valid_613665 = header.getOrDefault("X-Amz-Signature")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Signature", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Content-Sha256", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Date")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Date", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Credential")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Credential", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Security-Token")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Security-Token", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Algorithm")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Algorithm", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-SignedHeaders", valid_613671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613673: Call_UntagResource20161125_613660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_613673.validator(path, query, header, formData, body)
  let scheme = call_613673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613673.url(scheme.get, call_613673.host, call_613673.base,
                         call_613673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613673, url, valid)

proc call*(call_613674: Call_UntagResource20161125_613660; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20161125
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_613675 = newJObject()
  var body_613676 = newJObject()
  add(query_613675, "Resource", newJString(Resource))
  add(query_613675, "Operation", newJString(Operation))
  if body != nil:
    body_613676 = body
  result = call_613674.call(nil, query_613675, nil, nil, body_613676)

var untagResource20161125* = Call_UntagResource20161125_613660(
    name: "untagResource20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20161125_613661, base: "/",
    url: url_UntagResource20161125_613662, schemes: {Scheme.Https, Scheme.Http})
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
